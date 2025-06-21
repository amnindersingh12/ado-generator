# frozen_string_literal: true

class Record < ApplicationRecord
  belongs_to :user
  has_many :attendances, dependent: :destroy

  # --- New: Guest Functionality Associations ---
  # A record can be a guest of another record (its host)
  belongs_to :host, class_name: 'Record', foreign_key: 'parent_record_id', optional: true

  # A record can have multiple guests
  has_many :guests, class_name: 'Record', foreign_key: 'parent_record_id', dependent: :nullify
  # Using :nullify means if a host record is deleted, its guests will have their parent_record_id set to nil.
  # Change to dependent: :destroy if you want guests to be deleted when their host is.

  # Active Storage Attachments
  has_one_attached :photo do |attachable|
    attachable.variant :thumbnail, resize_to_limit: [100, 100]
  end
  has_one_attached :government_id_photo do |attachable|
    attachable.variant :thumbnail, resize_to_limit: [100, 100]
  end

  attribute :photo_data, :string

  # --- Validations ---

  # Name: Must be present and can optionally have a length limit
  validates :name, presence: { message: "Name cannot be blank." },
                   length: { maximum: 100, message: "Name cannot exceed 100 characters." }

  # Contact Number: Must be present, unique, and follow a specific format (e.g., 10-digit Indian mobile)
  validates :contact_number, presence: { message: "Contact number cannot be blank." },
                             uniqueness: { message: "This contact number is already registered." },
                             length: { is: 10, message: "Contact number must be exactly 10 digits long." }
  # Address: Presence is optional, but you can add length constraints if needed
  validates :address, length: { maximum: 255, message: "Address cannot exceed 255 characters." }, allow_blank: true

  # Pincode: Must be present, numerical, and exactly 6 digits (common for India)
  validates :pincode, presence: { message: "Pincode cannot be blank." },
                      numericality: { only_integer: true, message: "Pincode must be a number." },
                      length: { is: 6, message: "Pincode must be exactly 6 digits long." }

  # City: Must be present and can have a length limit
  validates :city, presence: { message: "City cannot be blank." },
                   length: { maximum: 100, message: "City name cannot exceed 100 characters." }

  # State: Must be present and can have a length limit
  validates :state, presence: { message: "State cannot be blank." },
                    length: { maximum: 100, message: "State name cannot exceed 100 characters." }

  # Date of Birth: Must be present and cannot be in the future
  validates :date_of_birth, presence: { message: "Date of Birth cannot be blank." }
  validate :date_of_birth_cannot_be_in_the_future, if: -> { date_of_birth.present? }

  # Father's Name: Must be present and can have a length limit
  validates :father_name, presence: { message: "Father's Name cannot be blank." },
                          length: { maximum: 100, message: "Father's Name cannot exceed 100 characters." }

  # Government ID Number: Must be present and can have a length/format based on ID type (e.g., Aadhaar, PAN)
  validates :government_id_number, presence: { message: "Government ID number cannot be blank." },
                                   length: { minimum: 5, maximum: 20, message: "Government ID number must be between 5 and 20 characters." } # Adjust length/format as per actual ID types

  # --- New: Guest-specific validations ---
  # parent_record_id must be present if is_guest is true
  validates :parent_record_id, presence: { message: "Guest must be associated with a host record." }, if: :is_guest?
  # parent_record_id must be absent (nil) if is_guest is false
  validates :parent_record_id, absence: { message: "cannot be present if the record is not a guest" }, unless: :is_guest?
  # A record cannot be a guest of itself
  validate :guest_cannot_be_its_own_host
  # Optional: A guest cannot be a guest of another guest (enforces single-level hierarchy)
  validate :guest_cannot_be_guest_of_guest

  # --- Ransackable Attributes & Associations ---
  def self.search_all(query)
      # Using 'records.' prefix for clarity, though often not strictly necessary
      # within the model scope unless there are table name conflicts.
      where("records.name LIKE :query OR
            records.email LIKE :query OR
            records.contact_number LIKE :query OR
            records.address LIKE :query OR
            records.city LIKE :query OR
            records.state LIKE :query OR
            records.father_name LIKE :query OR
            records.government_id_number LIKE :query", query: "%#{query}%")
    end

  # Allow Ransack to search on this virtual attribute
  # You might need to add other attributes if they are also searchable
  def self.ransackable_attributes(auth_object = nil)
    super + ['search_all'] # Add 'search_all' to the list of searchable attributes
  end

  # If you have custom scopes you want to search on
  def self.ransackable_scopes(auth_object = nil)
    super + [:search_all]
  end
  scope :search_by_query, ->(query_term) {
    # If the query term is blank, return all records (or handle as desired)
    return all if query_term.blank?

    # Prepare the search term for LIKE queries
    sanitized_query = "%#{query_term}%"

    # Construct the WHERE clause with explicit table qualification for ambiguous columns
    where("
      records.name LIKE :query OR
      records.email LIKE :query OR
      records.contact_number LIKE :query OR
      records.address LIKE :query OR
      records.city LIKE :query OR
      records.state LIKE :query OR
      records.father_name LIKE :query OR
      records.government_id_number LIKE :query    /* Qualified! */
    ", query: sanitized_query)
  }
  # Allow searching on these fields
  def self.ransackable_attributes(_auth_object = nil)
    # Use super to include existing ransackable attributes, then add new ones
    super + %w[is_guest parent_record_id]
  end

  def self.ransackable_associations(_auth_object = nil)
    # Use super to include existing ransackable associations, then add new ones
    super + %w[host guests]
  end

  # --- Custom Methods ---

  def age
    return unless date_of_birth

    now = Time.zone.now.to_date # Use Time.zone.now for timezone awareness
    dob = date_of_birth.to_date
    age = now.year - dob.year
    age -= 1 if now < dob + age.years
    age
  end

  private

  # Custom validation for date_of_birth
  def date_of_birth_cannot_be_in_the_future
    if date_of_birth > Date.current
      errors.add(:date_of_birth, "Date of Birth cannot be in the future.")
    end
  end

  # Custom validation: A guest cannot be its own host
  def guest_cannot_be_its_own_host
    if is_guest? && parent_record_id.present? && parent_record_id == id
      errors.add(:parent_record_id, "cannot be the same as the record itself.")
    end
  end

  # Custom validation: A guest cannot be a guest of another guest
  # This prevents multi-level guest hierarchies if desired.
  def guest_cannot_be_guest_of_guest
    # Only run if parent_record_id is present and we have a host object
    if is_guest? && host.present? && host.is_guest?
      errors.add(:parent_record_id, "cannot be a guest of another guest.")
    end
  end

   # --- START ADDED/REVERTED CODE FOR WEBCAM PHOTO HANDLING ---

  # Helper method to check if photo_data virtual attribute has content
  def photo_data_present?
    self.photo_data.present? && self.photo_data.start_with?('data:image/')
  end

  # This method decodes the base64 string and attaches it to the :photo Active Storage field.
  def set_photo_from_data
    return unless photo_data_present?

    # Extract content type (e.g., "image/png") and the base64 data itself
    content_type = self.photo_data.split(';')[0].split(':')[1]
    base64_image = self.photo_data.split(',')[1]

    temp_file = nil # Initialize temp_file to nil for ensure block
    begin
      decoded_image = Base64.decode64(base64_image)

      # Create a temporary file in memory/disk
      # `binmode: true` is important for binary data
      temp_file = Tempfile.new(["webcam_photo_#{SecureRandom.hex}", ".#{content_type.split('/')[1]}"], binmode: true)
      temp_file.write(decoded_image)
      temp_file.rewind # Rewind the file pointer to the beginning

      # Attach the temporary file to the Active Storage 'photo' attribute
      self.photo.attach(
        io: temp_file,
        filename: "profile_photo_#{Time.current.to_i}.#{content_type.split('/')[1]}",
        content_type: content_type
      )
    rescue StandardError => e
      # Add an error to the record if something goes wrong during photo processing
      errors.add(:photo, "could not be processed: #{e.message}")
      Rails.logger.error "Error processing webcam photo for Record #{self.id || 'new'}: #{e.message}"
      false # Return false to halt the saving process if there's an error
    ensure
      # Ensure the temporary file is closed and unlinked (deleted)
      temp_file.close if temp_file
      temp_file.unlink if temp_file
    end
  end
  # --- END ADDED/REVERTED CODE FOR WEBCAM PHOTO HANDLING ---
end
# frozen_string_literal: true

class Record < ApplicationRecord
  belongs_to :user
  has_many :attendances, dependent: :destroy

  # Active Storage Attachments
  has_one_attached :photo do |attachable|
    attachable.variant :thumbnail, resize_to_limit: [100, 100]
  end
  has_one_attached :government_id_photo do |attachable|
    attachable.variant :thumbnail, resize_to_limit: [100, 100]
  end

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



  # --- Ransackable Attributes & Associations ---

  # Allow searching on these fields
  def self.ransackable_attributes(_auth_object = nil)
    %w[
      name email contact_number address city state father_name
      pincode_str government_id_number_str date_of_birth created_at updated_at
    ]
  end

  # Make integers searchable as strings (for better Ransack flexibility)
  ransacker :pincode_str, type: :string do
    Arel.sql('CAST(pincode AS TEXT)')
  end

  ransacker :government_id_number_str, type: :string do
    Arel.sql('CAST(government_id_number AS TEXT)')
  end

  def self.ransackable_associations(auth_object = nil)
    %w[attendances photo_attachment photo_blob government_id_photo_attachment government_id_photo_blob user]
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
end
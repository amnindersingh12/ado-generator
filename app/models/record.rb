# frozen_string_literal: true

class Record < ApplicationRecord
  belongs_to :user
  has_many :attendances, dependent: :destroy
  has_one_attached :photo
  validates :name, presence: true
  has_one_attached :government_id_photo
  validates :contact_number, presence: true

 # Allow searching on these fields
  def self.ransackable_attributes(_auth_object = nil)
    %w[
      name email contact_number address city state father_name
      pincode_str government_id_number_str date_of_birth created_at updated_at
    ]
  end

  # Make integers searchable as strings
  ransacker :pincode_str, type: :string do
    Arel.sql('CAST(pincode AS TEXT)')
  end

  ransacker :government_id_number_str, type: :string do
    Arel.sql('CAST(government_id_number AS TEXT)')
  end

  def self.ransackable_associations(auth_object = nil)
    ["attendances", "government_id_photo_attachment", "government_id_photo_blob", "photo_attachment", "photo_blob", "user"]
  end

  def age
    return unless date_of_birth

    now = Time.zone.now.to_date
    dob = date_of_birth.to_date
    age = now.year - dob.year
    age -= 1 if now < dob + age.years
    age
  end
end

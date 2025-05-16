class Record < ApplicationRecord
  belongs_to :user
  has_many :attendances, dependent: :destroy
  has_one_attached :photo
  validates :name,  presence: true, uniqueness: true
  has_one_attached :government_id_photo
  validates :contact_number, presence: true, uniqueness: true

  def self.ransackable_attributes(auth_object = nil)
    [ "address", "city", "contact_number", "created_at", "date_of_birth", "father_name", "government_id_number", "id", "name", "pincode", "state", "updated_at", "user_id" ]
  end

  def self.search(search)
    if search
      where("name LIKE ?", "%#{search}%")
    else
      all
    end
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

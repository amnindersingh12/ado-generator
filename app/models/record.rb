class Record < ApplicationRecord
  belongs_to :user
  has_many :attendances, dependent: :destroy
  has_one_attached :photo
  validates :name, :photo, presence: true


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
end

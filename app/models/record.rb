class Record < ApplicationRecord
  belongs_to :user
  has_many :attendances, dependent: :destroy
  has_one_attached :photo
  validates :name, presence: true


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
# https://grok.com/share/c2hhcmQtMg%3D%3D_c452595e-824e-4b77-af5b-e04e5e1dfa0e

class Record < ApplicationRecord
  belongs_to :user
  has_one_attached :in_photo
  has_one_attached :out_photo
  validates :name, presence: true

  def self.search(search)
    if search
      where("name LIKE ?", "%#{search}%")
    else
      all
    end
    end
end

class Record < ApplicationRecord
  belongs_to :user
  has_one_attached :in_photo do |attachable|
    attachable.variant :thumb, resize_to_limit: [200, 200]
  end
  has_one_attached :out_photo do |attachable|
    attachable.variant :thumb, resize_to_limit: [200, 200]
  end
  validates :name, presence: true

  def self.search(search)
    if search
      where("name LIKE ?", "%#{search}%")
    else
      all
    end
    end
end

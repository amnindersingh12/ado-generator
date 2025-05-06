class Record < ApplicationRecord
  belongs_to :user
  has_one_attached :in_photo
  validates :name, presence: true

  def self.search(search)
    if search
      where("name LIKE ?", "%#{search}%")
    else
      all
    end
    end
end
# https://grok.com/share/c2hhcmQtMg%3D%3D_c452595e-824e-4b77-af5b-e04e5e1dfa0e

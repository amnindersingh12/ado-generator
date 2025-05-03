class Record < ApplicationRecord
  belongs_to :user
  has_one_attached :in_photo 
  has_one_attached :out_photo 
  validates :name, presence: true
end

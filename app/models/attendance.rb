class Attendance < ApplicationRecord
  belongs_to :user
  belongs_to :record
  validates :user_id, presence: true
  validates :record_id, presence: true
  # Allow either in_photo or out_photo to be present, not both required
  validates :in_photo, presence: true, unless: -> { out_photo.present? }
  validates :out_photo, presence: true, unless: -> { in_photo.present? }
  has_one_attached :in_photo do |attachable|
    attachable.variant :thumb, resize_to_limit: [ 200, 200 ]
  end
  has_one_attached :out_photo do |attachable|
    attachable.variant :thumb, resize_to_limit: [ 200, 200 ]
  end
  
end

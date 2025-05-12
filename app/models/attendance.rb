class Attendance < ApplicationRecord
  belongs_to :user
  belongs_to :record
  has_one_attached :in_photo do |attachable|
    attachable.variant :thumb, resize_to_limit: [ 200, 200 ]
  end
  has_one_attached :out_photo do |attachable|
    attachable.variant :thumb, resize_to_limit: [ 200, 200 ]
  end
  validates :in_time, presence: true, if: -> { out_time.present? }
end

class Record < ApplicationRecord
  belongs_to :user

  validates :name, presence: true
  validates :in_time, presence: true
  validates :out_time, presence: true
end

class Ride < ApplicationRecord
  belongs_to :driver, required: true
  validates :driver_id, :start_address, :destination_address, presence: true
end

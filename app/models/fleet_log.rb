require_relative 'application_record'
class FleetLog < ApplicationRecord
  belongs_to :fleet
end

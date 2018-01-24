require_relative 'application_record'
class FleetRanking < ApplicationRecord
  belongs_to :fleet
end

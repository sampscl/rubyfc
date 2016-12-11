class Game < ActiveRecord::Base
  has_many :fleet_files
  has_one :journal
end

class Fleet < ApplicationRecord
  has_and_belongs_to_many :games
  has_and_belongs_to_many :leagues
  has_many :fleet_logs, dependent: :destroy
  has_one :fleet_ranking, dependent: :destroy
end

class User < ApplicationRecord
  has_many :fleets
  has_and_belongs_to_many :games
  has_and_belongs_to_many :leagues
end

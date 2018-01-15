require_relative 'application_record'
class League < ApplicationRecord
  has_and_belongs_to_many :fleets
  has_and_belongs_to_many :users
  has_many :tournaments
end

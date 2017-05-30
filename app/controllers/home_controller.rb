class HomeController < ApplicationController
  def index
    @games = Game.all
    @fleets = Fleet.all
    @leagues = League.all
    @missions = Mission.all
    @tournaments = Tournament.all
    @users = User.all
  end
end

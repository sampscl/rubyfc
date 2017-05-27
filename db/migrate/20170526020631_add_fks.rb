class AddFks < ActiveRecord::Migration[5.1]
  def change
    create_table :fleets_games, id: false do |t|
      t.belongs_to :game, index: true
      t.belongs_to :fleet, index: true
    end
    create_table :fleets_leagues, id: false do |t|
      t.belongs_to :league, index: true
      t.belongs_to :fleet, index: true
    end
    create_table :games_users, id: false do |t|
      t.belongs_to :user, index: true
      t.belongs_to :game, index: true
    end
    create_table :leagues_users, id: false do |t|
      t.belongs_to :user, index: true
      t.belongs_to :league, index: true
    end
  end
end

class AddInitialColumnsToTables < ActiveRecord::Migration[5.1]
  def change
    # games
    add_column :games, :journal_filename, :string
    # user
    # tournament
    # league
    add_column :leagues, :name, :string
    # fleet_ranking
    add_column :fleet_rankings, :score, :number
    # fleet
    add_column :fleets, :filename, :string
    add_column :fleets, :name, :string
    # missions
    add_column :missions, :name, :string
    add_column :missions, :filename, :string
    # fleet log
    add_column :fleet_logs, :log_filename, :string
  end
end

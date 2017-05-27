class CreateFleetLogs < ActiveRecord::Migration[5.1]
  def change
    create_table :fleet_logs do |t|
      t.belongs_to :fleet
      t.timestamps
    end
  end
end

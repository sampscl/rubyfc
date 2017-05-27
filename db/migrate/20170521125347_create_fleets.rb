class CreateFleets < ActiveRecord::Migration[5.1]
  def change
    create_table :fleets do |t|
      t.belongs_to :fleet
      t.belongs_to :fleet_log
      t.timestamps
    end
  end
end

class CreateFleetFiles < ActiveRecord::Migration
  def change
    create_table :fleet_files do |t|
      t.string :path
      t.references :game, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end

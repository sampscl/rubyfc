class CreateJournals < ActiveRecord::Migration
  def change
    create_table :journals do |t|
      t.string :path
      t.references :game, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end

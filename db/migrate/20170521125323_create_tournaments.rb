class CreateTournaments < ActiveRecord::Migration[5.1]
  def change
    create_table :tournaments do |t|
      t.belongs_to :league
      t.timestamps
    end
  end
end

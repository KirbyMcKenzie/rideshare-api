class CreateRides < ActiveRecord::Migration[8.0]
  def change
    create_table :rides, id: :uuid do |t|
      t.references :driver, type: :uuid, foreign_key: true, null: false
      t.string :start_address
      t.string :destination_address
      t.decimal :score, precision: 10, scale: 6
      t.decimal :earnings, precision: 10, scale: 2
      t.decimal :ride_distance, precision: 10, scale: 2
      t.decimal :commute_distance, precision: 10, scale: 2
      t.integer :ride_duration_minutes
      t.integer :commute_duration_minutes
      t.timestamps
    end
  end
end

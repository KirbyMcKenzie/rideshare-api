class CreateDrivers < ActiveRecord::Migration[8.0]
  def change
    create_table :drivers, id: :uuid do |t|
      t.string :home_address
      t.timestamps
    end
  end
end

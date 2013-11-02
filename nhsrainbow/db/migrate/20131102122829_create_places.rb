class CreatePlaces < ActiveRecord::Migration
  def change
    create_table :places do |t|
      t.string :name
      t.float :latitude
      t.float :longitude
      t.text :description
      t.string :place_type

      t.timestamps
    end
  end
end

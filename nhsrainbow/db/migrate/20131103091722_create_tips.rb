class CreateTips < ActiveRecord::Migration
  def change
    create_table :tips do |t|
      t.integer :place_id
      t.text :tip

      t.timestamps
    end
  end
end

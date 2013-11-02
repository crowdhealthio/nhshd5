class CreateNhsTypes < ActiveRecord::Migration
  def change
    create_table :nhs_types do |t|
      t.string :name
      t.string :uri_key

      t.timestamps
    end
  end
end

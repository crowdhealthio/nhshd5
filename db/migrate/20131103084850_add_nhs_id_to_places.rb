class AddNhsIdToPlaces < ActiveRecord::Migration
  def change
  	add_column :places, :nhs_id, :string
  end
end

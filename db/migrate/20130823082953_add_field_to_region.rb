class AddFieldToRegion < ActiveRecord::Migration
  def self.up
    add_column :regions, :abbrev, :string
    remove_column :comunes, :region_id
  end

  def self.down
    remove_column :regions, :abbrev
    add_column :comunes, :region_id, :integer
  end
end

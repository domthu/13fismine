class AddKeyToTopMenus < ActiveRecord::Migration
  def self.up
    add_column :top_menus, :key, :string
  end

  def self.down
    remove_column :top_menus, :key
  end
end

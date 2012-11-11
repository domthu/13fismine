class AddKeyToTopMenus < ActiveRecord::Migration
  def self.up
    add_column :top_menus, :key, :string
    rename_column :top_sections, :style, :key

  end

  def self.down
    remove_column :top_menus, :key
    rename_column :top_sections, :key, :style
  end
end

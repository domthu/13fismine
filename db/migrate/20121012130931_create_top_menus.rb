class CreateTopMenus < ActiveRecord::Migration
  def self.up
    create_table :top_menus do |t|
      t.string :description
      t.integer :order

      t.timestamps
    end
    
    add_column :top_sections, :top_menu_id, :integer, :default => 1, :null => false
  end

  def self.down
    remove_column :top_sections, :top_menu_id
    drop_table :top_menus
  end
end

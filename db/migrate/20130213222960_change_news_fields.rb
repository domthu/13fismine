class ChangeNewsFields < ActiveRecord::Migration
  def self.up
  rename_column :news, :causale, :reply
  change_column :news, :reply, :text
  change_column :top_sections, :se_home_menu, :integer,  :default => 0, :limit => 4
  rename_column :top_sections, :se_home_menu, :hidden_menu
  add_column :top_menus, :se_visibile, :integer,  :default => 1, :limit => 4
   end

  def self.down
  rename_column :news, :reply, :causale
  rename_column :top_sections, :hidden_menu, :se_home_menu
  remove_column :top_menus, :se_visibile
  end
end

class AddFieldsToProject < ActiveRecord::Migration
  def self.up
    add_column :projects, :titolo, :string
    add_column :projects, :data_dal, :datetime
    add_column :projects, :data_al, :datetime
    add_column :projects, :search_key, :string
  end

  def self.down
    remove_column :projects, :search_key
    remove_column :projects, :data_al
    remove_column :projects, :data_dal
    remove_column :projects, :titolo
  end
end

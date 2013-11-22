class AddRoleIdToUser < ActiveRecord::Migration
  def self.up
    #default 2 is anonymous
    add_column :users, :role_id, :integer, :default => 2, :null => false
    rename_column :users, :organization_id, :cross_organization_id
    #add_column :users, :Codice, :string, :null => true
    add_column :organizations, :Codice, :string, :null => true
    add_column :assos, :Codice, :string, :null => true
  end

  def self.down
    #remove_column :users, :role_id
    #rename_column :users, :cross_organization_id, :organization_id
    raise IrreversibleMigration
  end
end

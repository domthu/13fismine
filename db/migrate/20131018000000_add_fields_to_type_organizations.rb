class AddFieldsToTypeOrganizations< ActiveRecord::Migration
  def self.up
    add_column :type_organizations, :type_sport, :boolean, :default => 1
    rename_column :users, :disabilitato, :no_newsletter
    change_column :users, :no_newsletter , :boolean, :default => 0
    remove_column :users, :iva_
   end

  def self.down
    remove_column :type_organizations, :type_sport
    rename_column :users, :no_newsletter, :disabilitato
    add_column :users, :iva_, :string, :limit => 25, :null => true
  end
end

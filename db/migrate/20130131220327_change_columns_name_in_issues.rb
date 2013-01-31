class ChangeColumnsNameInIssues < ActiveRecord::Migration
  def self.up
    rename_column :issues, :riassunto, :summary
    rename_column :issues, :titolo, :address_map
  end
  def self.down
    rename_column :issues, :summary, :riassunto
    rename_column :issues, :address_map, :titolo
  end
end

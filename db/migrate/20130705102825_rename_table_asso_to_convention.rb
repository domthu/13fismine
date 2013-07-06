class RenameTableAssoToConvention < ActiveRecord::Migration
  def self.up
    rename_table :assos, :conventions

    add_column :conventions, :region_id, :integer, :null => true
    add_column :conventions, :province_id, :integer, :null => true
    #se la copertura della convenzione e di tipo nazionale allora viene lasciato region e province a null
    add_column :conventions, :cross_organization_id, :integer, :null => true
    add_column :conventions, :user_id, :integer, :null => true
    add_column :conventions, :data_scadenza, :datetime
    add_column :conventions, :nota, :string
    add_column :conventions, :richiedinumeroregistrazione, :boolean
    #per ilmomento non serve pero potrebbe essere utile per definire i dati della newsletter o di fatturazione
    add_column :conventions, :comune_id, :integer, :null => true

  end

 def self.down
    remove_column :conventions, :region_id
    remove_column :conventions, :province_id
    remove_column :conventions, :cross_organization_id
    remove_column :conventions, :user_id
    remove_column :conventions, :data_scadenza
    remove_column :conventions, :nota
    remove_column :conventions, :richiedinumeroregistrazione

    rename_table :conventions, :assos
 end
end

#UPDATE conventions AS conv INNER JOIN organizations AS org ON conv.id = org.asso_id LEFT JOIN regions AS reg  ON reg.id = org.region_id LEFT JOIN provinces AS prov  ON prov.id = org.province_id SET conv.region_id = reg.id, conv.province_id = prov.id, conv.cross_organization_id = org.cross_organization_id, conv.user_id = org.user_id, conv.data_scadenza = org.data_scadenza, conv.nota = org.nota, conv.richiedinumeroregistrazione = org.richiedinumeroregistrazione, conv.comune_id = org.comune_id

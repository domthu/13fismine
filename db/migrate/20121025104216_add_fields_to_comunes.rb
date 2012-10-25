class AddFieldsToComunes < ActiveRecord::Migration
  def self.up
    add_column :comunes, :cap, :string
    add_column :comunes, :prefisso_tel, :string
    add_column :comunes, :abitanti, :integer
    add_column :comunes, :cod_fisco, :string
    add_column :comunes, :link_to_comune, :string
  end

  def self.down
    remove_column :comunes, :link_to_comune
    remove_column :comunes, :cod_fisco
    remove_column :comunes, :abitanti
    remove_column :comunes, :prefisso_tel
    remove_column :comunes, :cap
  end
end

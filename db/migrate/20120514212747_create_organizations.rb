class CreateOrganizations < ActiveRecord::Migration
  def self.up
    create_table :organizations do |t|
      t.integer :region_id, :null => true
      t.integer :province_id, :null => true
      t.integer :comune_id, :null => true
      t.integer :user_id, :null => true
      t.integer :asso_id, :null => true
      t.integer :cross_organization_id, :null => true
      t.datetime :data_scadenza
      t.string :nota
      t.string :testo2
      t.string :testo3
      t.text :numero1
      t.text :numero2
      t.text :numero3
      t.datetime :data1
      t.datetime :data2
      t.datetime :data3
      t.boolean :flag1, :default => 0
      t.boolean :flag2, :default => 0
      t.boolean :flag3, :default => 0
      t.boolean :richiedinumeroregistrazione

      t.timestamps
    end
  end

  def self.down
    drop_table :organizations
  end
end

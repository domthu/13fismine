class CreateOrganizations < ActiveRecord::Migration
  def self.up
    create_table :organizations do |t|
      t.integer :region_id
      t.integer :province_id
      t.datetime :data_scadenza
      t.integer :user_id
      t.string :nota
      t.string :testo2
      t.string :testo3
      t.text :numero1
      t.text :numero2
      t.text :numero3
      t.datetime :data1
      t.datetime :data2
      t.datetime :data3
      t.boolean :flag1
      t.boolean :flag2
      t.boolean :flag3
      t.boolean :richiedinumeroregistrazione
      t.integer :asso_id
      t.integer :cross_organization_id
      t.integer :comune_id

      t.timestamps
    end
  end

  def self.down
    drop_table :organizations
  end
end

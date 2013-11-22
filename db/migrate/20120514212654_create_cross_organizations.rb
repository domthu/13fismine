class CreateCrossOrganizations < ActiveRecord::Migration
  def self.up
    create_table :cross_organizations do |t|
      t.string :organizzazione
      t.string :sigla
      t.boolean :se_visibile, :default => 1
      t.integer :type_organization_id, :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :cross_organizations
  end
end

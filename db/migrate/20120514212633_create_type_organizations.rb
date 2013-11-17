class CreateTypeOrganizations < ActiveRecord::Migration
  def self.up
    create_table :type_organizations do |t|
      t.string :tipo
      t.string :descrizione
      t.integer :priorita

      t.timestamps
    end
  end

  def self.down
    drop_table :type_organizations
  end
end

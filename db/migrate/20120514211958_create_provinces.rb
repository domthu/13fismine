class CreateProvinces < ActiveRecord::Migration
  def self.up
    create_table :provinces do |t|
      t.string :name
      t.integer :region_id
      t.string :sigla

      t.timestamps
    end
  end

  def self.down
    drop_table :provinces
  end
end

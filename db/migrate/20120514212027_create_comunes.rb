class CreateComunes < ActiveRecord::Migration
  def self.up
    create_table :comunes do |t|
      t.string :name
      t.integer :province_id
      t.integer :region_id

      t.timestamps
    end
  end

  def self.down
    drop_table :comunes
  end
end

class CreateComunes < ActiveRecord::Migration
  def self.up
    create_table :comunes do |t|
      t.string :name
      t.integer :province_id, :null => false
      t.integer :region_id, :null => true

      t.timestamps
    end
  end

  def self.down
    drop_table :comunes
  end
end

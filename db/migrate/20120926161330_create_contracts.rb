class CreateContracts < ActiveRecord::Migration
  def self.up
    create_table :contracts do |t|
      t.string :name, :limit => 50, :default => "", :null => false
      t.text :description
      t.float :price, :null => false
      t.float :price_discount
      t.float :promo_price
      t.float :promo_price_discount
      t.datetime :promo_date_start
      t.datetime :promo_date_end
      t.integer :weight
      t.boolean :promote_to_frontpage
      t.integer :duration, :default => 12, :null => false
      t.integer :clicks, :default => 0, :null => false
      t.integer :type, :default => 1, :null => false
      #t.boolean :active
 
      t.timestamps
    end
  end

  def self.down
    drop_table :contracts
  end
end

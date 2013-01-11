class CreateReservations < ActiveRecord::Migration
  def self.up
    create_table :reservations do |t|
      t.integer :user_id, :null => false
      t.integer :issue_id, :null => false
      t.integer :num_persone, :null => true
      t.float :prezzo, :null => true
      t.text :msg,:limit => 1000, :null => true

      t.timestamps

    end
  end

  def self.down
    drop_table :reservations
  end
end

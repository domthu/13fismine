class CreateContractUsers < ActiveRecord::Migration
  def self.up
    create_table :contract_users do |t|
      t.integer :contract_id, :null => false
      t.integer :user_id, :null => false
      t.datetime :date
      t.datetime :scadenza
      t.integer :clicks
      t.text :note
      t.boolean :renewed

      t.timestamps
    end
    add_index :contract_users, :user_id
  end

  def self.down
    remove_index :contract_users, :user_id
    drop_table :contract_users
  end
end

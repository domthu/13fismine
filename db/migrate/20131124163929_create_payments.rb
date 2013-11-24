class CreatePayments < ActiveRecord::Migration
  def self.up
    create_table :payments do |t|
      t.text :pagamento

      t.timestamps
    end
    change_column :invoices, :user_id, :int, :null => true
  end

  def self.down
    drop_table :payments
  end

end

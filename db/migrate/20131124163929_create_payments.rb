class CreatePayments < ActiveRecord::Migration
  def self.up
    create_table :payments do |t|
      t.text :pagamento
      t.timestamps
    end
    change_column :invoices, :user_id, :int, :null => true
    add_column :invoices, :payment_id, :int , :null => true
    add_column :invoices, :footer, :text, :null => true
    remove_column :invoices, :pagamento
  end

  def self.down
    drop_table :payments
    remove_column :invoices, :payment_id
    remove_column :invoices, :footer
    add_column :invoices, :pagamento, :text
  end

end

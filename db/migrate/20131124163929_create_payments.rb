class CreatePayments < ActiveRecord::Migration
  def self.up
    create_table :payments do |t|
      t.text :pagamento, :limit => 100, :null => false
      t.text :abbrev, :limit => 3, :null => false
      t.timestamps
    end
    change_column :invoices, :user_id, :int, :null => true
    add_column :invoices, :payment_id, :int , :null => true
    add_column :invoices, :footer, :text, :null => true
    remove_column :invoices, :pagamento

    existing_payments = Payment.all()
    if (existing_payments.nil?) || (existing_payments.count < 1)
      Payment.create!(:id => 1, :abbrev => "BON", :pagamento => "bonifico bancario")
      Payment.create!(:id => 2, :abbrev => "WEB", :pagamento => "Pagamento online (Fismine)")
      Payment.create!(:id => 3, :abbrev => "DEN", :pagamento => "Contante")
      Payment.create!(:id => 4, :abbrev => "POS", :pagamento => "Bonifico postale")
      Payment.create!(:id => 5, :abbrev => "CAR", :pagamento => "Carte di credito o di debito")
    end

  end
  def self.down
    drop_table :payments
    remove_column :invoices, :payment_id
    remove_column :invoices, :footer
    add_column :invoices, :pagamento

  end
end

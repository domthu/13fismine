class CreateInvoices < ActiveRecord::Migration
  def self.up
    create_table :invoices do |t|
      t.integer :user_id
      t.integer :numero_fattura
      t.datetime :data_fattura
      t.string :sezione
      t.integer :anno
      t.float :tariffa
      t.text :sconto
      t.text :iva
      t.string :pagamento

      t.timestamps
    end
  end

  def self.down
    drop_table :invoices
  end
end

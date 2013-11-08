class AddColumnsConventionIdToInvoice < ActiveRecord::Migration
  def self.up
     add_column :invoices, :convention_id, :integer, :default => nil, :null => true
     add_column :invoices, :mittente, :text
     add_column :invoices, :destinatario, :text
     add_column :invoices, :description, :text
     #add_column :invoices, :abbo_dal, :date, :default => nil, :null => true
     #add_column :invoices, :abbo_al, :date, :default => nil, :null => true
     change_column :invoices, :sconto, :float
     change_column :invoices, :iva, :float
     #add_column :invoices, :pagamento, :string
     add_column :invoices, :contract_user_id, :integer, :default => nil, :null => true
  end

  def self.down
     #remove_column :invoices, :contract_user_id
     #remove_column :invoices, :pagamento
     change_column :invoices, :iva, :text
     change_column :invoices, :sconto, :text
     #remove_column :invoices, :abbo_al
     #remove_column :invoices, :abbo_dal
     remove_column :invoices, :description
     remove_column :invoices, :destinatario
     remove_column :invoices, :mittente
     remove_column :invoices, :convention_id
  end
end

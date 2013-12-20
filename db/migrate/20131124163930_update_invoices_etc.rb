class UpdateInvoicesEtc < ActiveRecord::Migration
  def self.up
    add_column :invoices, :se_pagato, :boolean, :default => 1
    add_column :invoices, :contatto, :text, :null => true
    add_column :invoices, :attached_invoice, :text, :null => true
    add_column :invoices, :date_sended, :date
    add_column :conventions, :partitaiva, :string, :null => true
    add_column :conventions, :codicefiscale, :string, :null => true

  end

  def self.down
    remove_column :invoices, :se_pagato
    remove_column :invoices, :contatto
    remove_column :invoices, :attached_invoice
    remove_column :invoices, :date_sended
    remove_column :conventions, :partitaiva
    remove_column :conventions, :codicefiscale

  end
end

class AddFieldsToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :codice, :integer
    add_column :users, :nome, :string
    add_column :users, :titolo, :string
    add_column :users, :soc, :string
    add_column :users, :parent, :integer
    add_column :users, :note, :text

    add_column :users, :pwd, :string
    #add_column :users, :login, :string  Kappao esiste già
    add_column :users, :login_fisco, :string

    add_column :users, :asso_id, :integer, :null => true
    #add_column :users, :account_id, :integer
    add_column :users, :organization_id, :integer, :null => true
    add_column :users, :comune_id, :integer, :null => true
    add_column :users, :sede, :string
    add_column :users, :indirizzo, :string
    add_column :users, :cap, :string
    add_column :users, :prov, :string
    add_column :users, :telefono, :string
    add_column :users, :fax, :string
    #add_column :users, :mail, :string  Kappao esiste già
    add_column :users, :mail_fisco, :string
    add_column :users, :telefono2, :string
    add_column :users, :mail2, :string
    add_column :users, :data, :string
    add_column :users, :datascadenza, :datetime
    add_column :users, :sez, :string
    add_column :users, :iva_, :string
    add_column :users, :codicefiscale, :string
    add_column :users, :partitaiva, :string

    add_column :users, :annotazioni, :text
    add_column :users, :tariffa_precedente, :float
    add_column :users, :sconto_precedente, :text
    add_column :users, :iva_precedente, :text
    add_column :users, :pagamento_precedente, :string
    add_column :users, :data_ultimo_pagamento, :datetime
    add_column :users, :data_accredito, :datetime
    add_column :users, :anno_competenza, :integer
    add_column :users, :crediti, :integer

    add_column :users, :registrato, :string
    add_column :users, :num_reg_coni, :string
    add_column :users, :abbonato, :boolean, :default => 0
    add_column :users, :conferma_registrazione, :boolean, :default => 1
    add_column :users, :disabilitato, :boolean, :default => 0
    add_column :users, :power_user, :boolean, :default => 0
    add_column :users, :forum_redattore, :boolean, :default => 0
    add_column :users, :forum_notifica, :boolean, :default => 0
    #User.update_all "type = 'User'"
  end

  def self.down
    remove_column :users, :forum_notifica
    remove_column :users, :forum_redattore
    remove_column :users, :num_reg_coni
    remove_column :users, :power_user
    remove_column :users, :crediti
    remove_column :users, :parent
    remove_column :users, :disabilitato
    remove_column :users, :abbonato
    remove_column :users, :conferma_registrazione
    remove_column :users, :anno_competenza
    remove_column :users, :data_accredito
    remove_column :users, :data_ultimo_pagamento
    remove_column :users, :pagamento_precedente
    remove_column :users, :iva_precedente
    remove_column :users, :sconto_precedente
    remove_column :users, :tariffa_precedente
    remove_column :users, :annotazioni
    remove_column :users, :partitaiva
    remove_column :users, :codicefiscale
    remove_column :users, :iva_
    remove_column :users, :sez
    remove_column :users, :note
    remove_column :users, :prov
    remove_column :users, :cap
    remove_column :users, :datascadenza
    remove_column :users, :data
    remove_column :users, :registrato
    remove_column :users, :pwd
    remove_column :users, :mail2
    #remove_column :users, :login  Kappao esiste già
    remove_column :users, :login_fisco
    remove_column :users, :telefono2
    #remove_column :users, :mail  Kappao esiste già
    remove_column :users, :mail_fisco 
    remove_column :users, :fax
    remove_column :users, :telefono
    remove_column :users, :indirizzo
    remove_column :users, :sede
    remove_column :users, :soc
    remove_column :users, :titolo
    remove_column :users, :nome
    remove_column :users, :codice
    remove_column :users, :organization_id
    remove_column :users, :comune_id
    #remove_column :users, :account_id
    remove_column :users, :asso_id
  end
end

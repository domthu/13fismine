class CreateNewsletterUsers < ActiveRecord::Migration
  def self.up
    create_table :newsletter_users do |t|
      t.string :email_type :limit => 30, :null => false
      t.integer :user_id, :null => false
      t.integer :asso_id, :null => true
      t.datetime :data_scadenza, :null => true
      t.text :html
      t.integer :newsletter_id, :null => true # on modo da usare per altri scopi
      #in particolare per la gestione abbonamento per tracciare gli invii
      t.text :errore, :null => true
      t.boolean :sended, :default => 0  #in modo da inviare durante la notte

      t.timestamps
    end
  end

  def self.down
    drop_table :newsletter_users
  end
end

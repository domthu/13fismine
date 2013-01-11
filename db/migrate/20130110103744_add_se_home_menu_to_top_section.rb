class AddSeHomeMenuToTopSection < ActiveRecord::Migration
  def self.up

    #menu
    add_column :top_sections, :se_home_menu, :integer, :default => 0, :null => false
    #news.status_id = 0 default
    #news.status_id = 1 CONVEGNI
    #news.status_id = 2 NEWS E SPORT

    #Quesiti
    add_column :issues, :news_id, :integer, :null => true
    add_column :news, :status_id, :integer, :default => 1, :null => true
    #news.status_id = 0 RIFIUTATO
    #news.status_id = 1 IN ATTESA
    #news.status_id = 2 ACCETTATO
    add_column :news, :causale, :string, :limit => 255, :null => true


    #Eventi
    add_column :issues, :se_prenotazione, :boolean, :default => 0, :null => true
#    create_table :reservations do |t|
#      t.integer :user_id, :null => false
#      t.integer :issue_id, :null => false
#      t.integer :num_persone
#      t.float :prezzo, :null => true
#      t.text :note, :limit => 1000, :null => true

#      t.timestamps
#    end

    #chisiamo
#    create_table :profiles do |t|
#      t.integer :user_id, :null => false
#      t.text :titoli, :limit => 1000, :null => true
#      t.text :curriculum, :limit => 2000, :null => true
#      t.string :immagine_url, :limit => 255, :null => true
#      t.string :external_url, :limit => 255, :null => true

#      t.timestamps
#    end

  end

  def self.down
#    drop_table :profiles
#    drop_table :reservations
    remove_column :issues, :se_prenotazione
    remove_column :news, :causale
    remove_column :news, :status_id
    remove_column :issues, :news_id
    remove_column :top_sections, :se_home_menu
  end
end

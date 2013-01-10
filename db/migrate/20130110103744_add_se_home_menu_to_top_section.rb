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
    add_column :news, :causale, :limit => 255, :string, :null => true


    #Eventi
    add_column :issues, :se_prenotazione, :boolean, :default => 0, :null => true
    create_table :reservations do |t|
      t.integer :user_id, :null => false
      t.integer :issue_id, :null => false
      t.integer :num_persone
      t.float :prezzo, :null => true
      t.text :note, :limit => 1000, :null => true

      t.timestamps
    end

    #chisiamo
    create_table :profiles do |t|
      t.integer :user_id, :null => false
      t.string :url, :null => true
      t.text :titoli, :limit => 1000, :null => true
      t.text :curriculum, :limit => 2000, :null => true
      t.string :allegato, :limit => 250, :null => true

      t.timestamps
    end

       * User data : nome cognome email contatti
      FK UserId
   * url esterna verso una pagina personale
   * foto
   * titoli
   * curriculum
   * PDF allegato Document
  end

  def self.down
    remove_column :top_sections, :se_home_menu
    drop_table :reservations
  end
end
#2/4 QUESITO
#  * Status
#  * Idarticolo

#  creazione Utente
#    News va in progetto QUESITI e-quesiti
#    prende lo Stato IN ATTESA
#      CAMPO DA CREARE
#  MariaCristina accede al Progetto QUESITI
#    1/3 lo rifiuta e mette lo Stato NON ATTINENTE
#               Scrive Causale
#      CAMPO DA CREARE
#    pagina news modifica add PULSANTI ACCETTA
#    2/3 Al click Andiamo su Nuovo Articolo
#        - imposta Issue.new con l'id della news
#        - imposta un collaboratore
#        - definisce Top
#        Al salvattaggio
#          * NEWS mette lo stato IN LAVORAZIONE
#          * ARTICOLO Crea ed associa alla news

#    3/3 sceglie l'edizione (di default )
#        SPOSTA su un edizione in pubblicazione

#NOTA: Imporrt dei dati --> rivedere la procedura di import per creare
#    news con authorid = il cliente
#    articolo legato alla news con authorid = il collaboratore

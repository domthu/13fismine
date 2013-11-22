class RemoveColumnsHtmlFromNewsletterUsers < ActiveRecord::Migration
  def self.up
  remove_column :newsletter_users, :data_scadenza
  remove_column :newsletter_users, :html
  add_column :newsletter_users, :information_id, :int, :null => true
  add_column :newsletter_users, :email_type_id, :int, :null => false

   create_table :information do |i|
      i.string :subject, :limit => 100, :null => true
      i.string :description, :limit => 1000, :null => false
   end

   create_table :email_types do |e|
      e.string :description, :limit => 30, :null => false
   end

   create_table :newsletter_archives do |t|
      t.integer :email_type_id, :limit => 30, :null => false
      t.integer :user_id, :null => false
      t.integer :asso_id, :null => true
      t.integer :newsletter_id, :null => true # on modo da usare per altri scopi
      t.integer :information_id, :null => true
      t.boolean :sended, :default => 0  #in modo da inviare durante la notte
      t.datetime :created_at, :null => false
   end

  #do rake move_error and after do migration
  #remove_column :newsletter_users, :errore
  #remove_column :newsletter_users, :email_type

  end

  def self.down
    drop_table :newsletter_archives
    drop_table :information
    drop_table :email_types
    #add_column :newsletter_users, :html, :text
    add_column :newsletter_users, :html, :string, :limit => 3000
    add_column :newsletter_users, :data_scadenza, :datetime
    remove_column :newsletter_users, :email_type_id
    remove_column :newsletter_users, :information_id
  end
end

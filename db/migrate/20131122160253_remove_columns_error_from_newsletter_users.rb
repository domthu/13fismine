class RemoveColumnsErrorFromNewsletterUsers < ActiveRecord::Migration
  def self.up
    remove_column :newsletter_users, :errore
    remove_column :newsletter_users, :email_type
  end

  def self.down
    add_column :newsletter_users, :errore, :text
    add_column :newsletter_users, :email_type, :limit => 30, :null => true
  end
end

class AddAttachmentsPhotoToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :photo_file_name, :string
    add_column :users, :photo_content_type, :string
    add_column :users, :photo_file_size, :integer
    add_column :users, :photo_updated_at, :datetime
    add_column :projects, :system, :boolean, :default => 0
    rename_column :users, :abbonato, :use_gravatar
    change_column :users, :use_gravatar ,:default => 1
    rename_column :users, :sez, :codice_attivazione
    rename_column :conventions, :Codice, :codice_attivazione
  end

  def self.down
    remove_column :users, :photo_file_name
    remove_column :users, :photo_content_type
    remove_column :users, :photo_file_size
    remove_column :users, :photo_updated_at
    remove_column :projects, :system
    rename_column :users,  :use_gravatar, :abbonato
    rename_column :users,  :codice_attivazione, :sez
    rename_column :conventions, :codice_attivazione,:Codice
  end
end

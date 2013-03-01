class UserProfilesGroups < ActiveRecord::Migration
  def self.up
    add_column :user_profiles, :fs_qualifica, :string, :limit => 65
    add_column :user_profiles, :fs_tel, :string, :limit => 25
    add_column :user_profiles, :fs_fax, :string, :limit => 25
    add_column :user_profiles, :fs_skype, :string, :limit => 65
    add_column :user_profiles, :fs_mail, :string, :limit => 65
    add_column :user_profiles, :display_in, :integer, {:limit =>1, :default => 1, :null => false}
    rename_column :user_profiles, :immagine_url, :use_gravatar
    change_column :user_profiles, :use_gravatar, :boolean, {:default => 1, :null => false}
    change_column :top_sections, :hidden_menu , :integer, {:limit =>1, :default => 0, :null => false}
   end

  def self.down
    remove_column :user_profiles, :fs_qualifica
    remove_column :user_profiles, :fs_tel
    remove_column :user_profiles, :fs_fax
    remove_column :user_profiles, :fs_skype
    remove_column :user_profiles, :fs_mail
    remove_column :user_profiles, :display_in
    rename_column :user_profiles, :use_gravatar, :immagine_url
  end
end

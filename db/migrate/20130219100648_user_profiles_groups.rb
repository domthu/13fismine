class UserProfilesGroups < ActiveRecord::Migration
  def self.up
    add_column :user_profiles, :fs_qualifica, :string, :limit => 65
    add_column :user_profiles, :fs_tel, :string, :limit => 25
    add_column :user_profiles, :fs_fax, :string, :limit => 25
    add_column :user_profiles, :fs_skype, :string, :limit => 65
    add_column :user_profiles, :fs_mail, :string, :limit => 65
    add_column :user_profiles, :display_in, :boolean, {:default => 1, :null => false}
    change_column :top_sections, :hidden_menu , :boolean, {:default => 0}
  end

  def self.down

    remove_column :user_profiles, :fs_qualifica
    remove_column :user_profiles, :fs_tel
    remove_column :user_profiles, :fs_fax
    remove_column :user_profiles, :fs_skype
    remove_column :user_profiles, :fs_mail
    remove_column :user_profiles, :display_in

  end
end

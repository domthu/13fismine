class UserProfilesGroups < ActiveRecord::Migration
  def self.up
      create_table :user_profiles_roles do |t|
      t.string :description, :limit => 255
      t.integer :user_profile_id, :null => false
      t.timestamps
    end
    add_column :user_profiles, :fs_qualifica, :string, :limit => 65
    add_column :user_profiles, :fs_tel, :string, :limit => 25
    add_column :user_profiles, :fs_fax, :string, :limit => 25
    add_column :user_profiles, :fs_skype, :string, :limit => 65
    add_column :user_profiles, :fs_mail, :string, :limit => 65
    add_column :user_profiles, :se_staff, :integer, {:default => 0, :limit => 4}
    add_column :user_profiles, :se_visibile, :integer, {:default => 1, :limit => 4}
  end

  def self.down

    remove_column :user_profiles, :fs_qualifica
    remove_column :user_profiles, :fs_tel
    remove_column :user_profiles, :fs_fax
    remove_column :user_profiles, :fs_skype
    remove_column :user_profiles, :fs_mail
    remove_column :user_profiles, :se_staff
    remove_column :user_profiles, :se_visibile

    remove_table :user_profiles_roles
  end
end

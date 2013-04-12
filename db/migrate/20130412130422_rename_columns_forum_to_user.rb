class RenameColumnsForumToUser < ActiveRecord::Migration
  def self.up
    add_index :users, :role_id
    add_index :users, :mail
    add_index :users, :login

    rename_column :users, :forum_notifica, :se_privacy
    rename_column :users, :forum_redattore, :se_condition

  end

  def self.down

    rename_column :users, :se_condition, :forum_redattore
    rename_column :users, :se_privacy, :forum_notifica

    remove_index :users, :login
    remove_index :users, :mail
    remove_index :users, :role_id
  end
end

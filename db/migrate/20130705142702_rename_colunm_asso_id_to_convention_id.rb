class RenameColunmAssoIdToConventionId < ActiveRecord::Migration
  def self.up
    rename_column :users, :asso_id, :convention_id
    rename_column :cross_groups, :asso_id, :convention_id
    rename_column :newsletter_users, :asso_id, :convention_id

    #limitazione per utenti che non hanno un abbonamento
    add_column :top_sections, :limited, :boolean, :default => 0
    remove_column :cross_organizations, :organizzazione
  end

  def self.down
    rename_column :users, :convention_id, :asso_id
    rename_column :cross_groups, :convention_id, :asso_id
    rename_column :newsletter_users, :convention_id, :asso_id
    remove_column :top_sections, :limited
    add_column :cross_organizations, :organizzazione, :string
  end
end

class AddFieldsToConvenction < ActiveRecord::Migration
  def self.up
    add_column :group_banners, :convention_id, :integer, :null => true
    add_column :conventions, :logo_in_fe, :boolean, :default => 1
    add_column :conventions, :priorita_logo_fe, :integer, :default => 0
    add_column :group_banners, :visibile_web, :boolean, :default => 1
    add_column :group_banners, :visibile_mail, :boolean, :default => 0
    remove_column :group_banners, :se_visibile
    remove_column :group_banners, :se_prima_pagina
    remove_column :group_banners, :impressions
    remove_column :group_banners, :impressions_history
    remove_column :group_banners, :clicks
    remove_column :group_banners, :banner
    remove_column :conventions, :logo
    remove_column :conventions, :consulente
  end

  def self.down
    remove_column :group_banners, :convention_id
    remove_column :conventions, :logo_in_fe
    remove_column :conventions, :priorita_logo_fe
    remove_column :group_banners, :visibile_web
    remove_column :group_banners, :visibile_mail
    add_column :group_banners, :se_visibile, :boolean, :default => 1
    add_column :group_banners, :se_prima_pagina, :boolean, :default => 1
    add_column :group_banners, :impressions, :integer, :default => 0
    add_column :group_banners, :impressions_history, :integer, :default => 0
    add_column :group_banners, :clicks, :integer, :default => 0
    add_column :group_banners, :banner, :string
    add_column :conventions, :logo, :string
    add_column :conventions, :consulente, :string
  end
end

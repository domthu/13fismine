class CreateGroupBanners < ActiveRecord::Migration
  def self.up
    create_table :group_banners do |t|
      t.string :espositore
      t.string :url
      t.integer :priorita
      t.string :posizione
      t.boolean :se_visibile, :default => 0
      t.string :banner
      t.integer :impressions
      t.integer :clicks
      t.text :didascalia
      t.boolean :se_prima_pagina, :default => 0
      t.integer :impressions_history

      t.timestamps
    end
  end

  def self.down
    drop_table :group_banners
  end
end

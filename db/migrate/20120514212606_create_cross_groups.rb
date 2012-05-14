class CreateCrossGroups < ActiveRecord::Migration
  def self.up
    create_table :cross_groups do |t|
      t.integer :asso_id
      t.integer :group_banner_id
      t.boolean :se_visibile

      t.timestamps
    end
  end

  def self.down
    drop_table :cross_groups
  end
end

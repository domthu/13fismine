class CreateCrossGroups < ActiveRecord::Migration
  def self.up
    create_table :cross_groups do |t|
      t.integer :asso_id, :null => false
      t.integer :group_banner_id, :null => false
      t.boolean :se_visibile, :default => 1

      t.timestamps
    end
  end

  def self.down
    drop_table :cross_groups
  end
end

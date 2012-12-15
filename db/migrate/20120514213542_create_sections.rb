class CreateSections < ActiveRecord::Migration
  def self.up
    create_table :sections do |t|
      t.string :sezione
      t.boolean :protetto, :default => 1
      t.integer :ordinamento
      t.integer :top_section_id, :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :sections
  end
end

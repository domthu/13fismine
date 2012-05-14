class CreateTopSections < ActiveRecord::Migration
  def self.up
    create_table :top_sections do |t|
      t.string :sezione_top
      t.integer :ordinamento
      t.boolean :se_visibile
      t.string :immagine
      t.string :style

      t.timestamps
    end
  end

  def self.down
    drop_table :top_sections
  end
end

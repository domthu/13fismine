class CreateNewsletters < ActiveRecord::Migration
  def self.up
    create_table :newsletters do |t|
      t.integer :project_id, :null => false
      t.datetime :data
      t.text :html
      t.boolean :sended, :default => 0  #in modo da programmare durante la notte

      t.timestamps
    end
  end

  def self.down
    drop_table :newsletters
  end
end

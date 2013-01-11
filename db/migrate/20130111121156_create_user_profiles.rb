class CreateUserProfiles < ActiveRecord::Migration
  def self.up
    create_table :user_profiles do |t|
      t.integer :user_id, :null => false
      t.text :titoli, :limit => 1000, :null => true
      t.text :curriculum, :limit => 2000, :null => true
      t.string :immagine_url, :limit => 255, :null => true
      t.string :external_url, :limit => 255, :null => true

      t.timestamps
    end
  end

  def self.down
    drop_table :user_profiles
  end
end

class ChangeColumnsDataToUser < ActiveRecord::Migration
  def self.up
   change_column :users, :data, :date
   change_column :users, :datascadenza, :date
  end

  def self.down
   change_column :users, :data, :string
   change_column :users, :datascadenza, :datetime
  end
end

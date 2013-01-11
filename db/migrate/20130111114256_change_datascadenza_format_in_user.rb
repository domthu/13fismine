class ChangeDatascadenzaFormatInUser < ActiveRecord::Migration
  def self.up
   change_column :organizations, :data_scadenza, :date
  end

  def self.down
   change_column :organizations, :data_scadenza, :datetime
  end
end

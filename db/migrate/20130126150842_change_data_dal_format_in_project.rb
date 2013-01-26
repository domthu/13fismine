class ChangeDataDalFormatInProject < ActiveRecord::Migration
  def self.up
   change_column :projects, :data_dal, :date
   change_column :projects, :data_al, :date
  end

  def self.down
   change_column :projects, :data_al, :datetime
   change_column :projects, :data_dal, :datetime
  end
end

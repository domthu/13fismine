class Comune < ActiveRecord::Base

  #domthu20120516
  has_many :users, :dependent => :nullify
  has_many :organizations, :dependent => :nullify

  belongs_to :province, :class_name => 'Province', :foreign_key => 'province_id'

  def to_s
    name #+ '(' + ?codice fiscale? + ')'
  end

  #alias :name :to_s

end

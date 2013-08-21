class Comune < ActiveRecord::Base

  #domthu20120516
  has_many :users, :dependent => :nullify
  has_many :organizations, :dependent => :nullify

  belongs_to :province, :class_name => 'Province', :foreign_key => 'province_id'

  def self.find_by_first_letter(chr)
    letter= chr || 'A'
      find(:all, :conditions => ['name LIKE ?', "#{letter}%"], :order => 'name ASC')
    end
  def to_s
    name #+ '(' + ?codice fiscale? + ')'
  end

end

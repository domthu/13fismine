class Comune < ActiveRecord::Base

  #domthu20120516
  has_many :users, :dependent => :nullify
  has_many :organizations, :dependent => :nullify

  belongs_to :province, :class_name => 'Province', :foreign_key => 'province_id'

  def self.find_by_first_letter(chr , ord  )
    letter= chr || 'A'
      find(:all, :conditions => ['comunes.name LIKE ?', "#{letter}%"], :include => [[ :province => :region ]] , :order => ord )
    end

  def to_s
    str = self.name
    str += (self.province.nil? ? "" : " " + self.province.name_full)
    str += ((self.province.nil? || self.province.region.nil?) ? "" : "::" + self.province.region.name) # .upcase)
    return str
  end

  alias :name_full :to_s
  #alias :name :to_s

end

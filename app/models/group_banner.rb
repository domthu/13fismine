class GroupBanner < ActiveRecord::Base

  #domthu20120516
  #http://guides.rubyonrails.org/v2.3.8/association_basics.html#choosing-between-belongs-to-and-has-one
  #2.8 Choosing Between has_many :through and has_and_belongs_to_many
  has_many :cross_groups, :dependent => :nullify
  has_many :assos, :through => :cross_groups, :dependent => :delete_all

  #string
  validates_presence_of :espositore
  validates_uniqueness_of :espositore, :case_sensitive => false
  validates_length_of :espositore, :maximum => 255

  #integer
  validates_presence_of :priorita
  validates_numericality_of :priorita, :allow_nil => false

  #boolean
  validates_presence_of :se_visibile

  #text-area? CSS? HTML area
  validates_length_of :didascalia, :maximum => 4000

  def to_s
    espositore.to_s
  end

  alias :name :to_s

end

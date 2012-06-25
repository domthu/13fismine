class Asso < ActiveRecord::Base

  #domthu20120516
  has_many :users, :dependent => :nullify
  has_many :organizations, :dependent => :nullify
  #http://guides.rubyonrails.org/v2.3.8/association_basics.html#choosing-between-belongs-to-and-has-one
  #2.8 Choosing Between has_many :through and has_and_belongs_to_many
  has_many :cross_groups, :dependent => :nullify
  #has_many :group_banners, :through => :cross_group, :dependent => :delete
  has_many :group_banners, :through => :cross_group, :dependent => :delete_all

  #string
  validates_presence_of :ragione_sociale
  validates_uniqueness_of :ragione_sociale, :case_sensitive => false
  validates_length_of :ragione_sociale, :maximum => 255
  validates_presence_of :email
  validates_uniqueness_of :email, :case_sensitive => false
  validates_length_of :email, :maximum => 100

  #text-area? CSS? HTML area
  validates_length_of :comunicazioni, :maximum => 4000

  def to_s
    ragione_sociale.to_s
  end

  alias :name :to_s

end

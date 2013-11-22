class TypeOrganization < ActiveRecord::Base

  #domthu20120516
  has_many :cross_organizations, :dependent => :destroy
  has_many :conventions, :through => :cross_organizations

  #uniqueness of tipo
  validates_uniqueness_of :tipo

  def to_s
    tipo
  end

  alias :name :to_s


end

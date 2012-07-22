class TypeOrganization < ActiveRecord::Base

  #domthu20120516
  has_many :cross_organizations, :dependent => :destroy


  def to_s
    tipo
  end

  alias :name :to_s


end

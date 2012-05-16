class TypeOrganization < ActiveRecord::Base

  #domthu20120516
  has_many :cross_organizations, :dependent => :destroy

end

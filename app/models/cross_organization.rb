class CrossOrganization < ActiveRecord::Base

  #domthu20120516
  has_many :organizations, :dependent => :nullify
  belongs_to :type_organization, :class_name => 'TypeOrganization', :foreign_key => 'type_organization_id'

end

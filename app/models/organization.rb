class Organization < ActiveRecord::Base

  #domthu20120516
  #has_many :users, :dependent => :nullify
  belongs_to :user

  belongs_to :region, :class_name => 'Region', :foreign_key => 'region_id'#, :default => null
  belongs_to :province, :class_name => 'Province', :foreign_key => 'province_id'#, :default => null
  belongs_to :comune, :class_name => 'Comune', :foreign_key => 'comune_id'#, :default => null
  #2.7 Choosing Between belongs_to and has_one
  belongs_to :referente, :class_name => 'User', :foreign_key => 'user_id'#, :default => null
  belongs_to :asso, :class_name => 'Asso', :foreign_key => 'asso_id'
  belongs_to :cross_organization, :class_name => 'CrossOrganization', :foreign_key => 'cross_organization_id'

  def to_s
    asso.name + ' --> ' + region.name + ' :: ' + province.name
    #'pippo'
  end

  alias :name :to_s

#  def havePowerUser?
#    !self.referente.blank && self.referente.power_user
#  end 

end

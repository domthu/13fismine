class CrossOrganization < ActiveRecord::Base

  #domthu20120516
  #ERROR undefined local variable or method `null' for #<Class:0xb656c5b4>
  has_many :organizations#, :dependent => :nullify
  
  #has_many :assos, :through => :organizations, :dependent => :delete_all
  has_many :users #, :dependent => :nullify
  belongs_to :type_organization, :class_name => 'TypeOrganization', :foreign_key => 'type_organization_id'

  #validation on uniqueness on two attributes
  validates_uniqueness_of :sigla, :scope => :type_organization_id
  #rails 3 validates :zipcode, :uniqueness => {:scope => :recorded_at}

  ###NON USARE PIU organizzazione
  def to_s
    type_organization.to_s + ' :: ' + sigla #to_s
  end

  alias :name :to_s

  #ERROR fail to grab related table using  @cross_organization.organizations
  def organizations2
    Organization.find(:all, :conditions => ["cross_organization_id == ?", self.id.to_s], :limit => 10)
  end

end

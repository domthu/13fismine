class CrossOrganization < ActiveRecord::Base
  has_attached_file :image, :styles => {:l => ["200x200#", :png, :jpg],
                                        :m => ["80x80#", :png, :jpg],
                                        :s => ["48x48#", :png, :jpg],
                                        :xs =>["32x32#", :png, :jpg]},
                    :url  =>  "commons/organizations/:id:style.:extension" ,
                    :path =>  "#{RAILS_ROOT}/public/images/commons/organizations/:id:style.:extension" ,
                    :default_style => :l,
                    :default_url => "commons/:style_ico-no-image.jpg"
  validates_attachment_size :image, :less_than => 200.kilobytes
  validates_attachment_content_type :image, :content_type => ['image/jpeg', 'image/png', 'image/gif', 'image/bmp']

  #domthu20120516
  #ERROR undefined local variable or method `null' for #<Class:0xb656c5b4>
  has_many :organizations#, :dependent => :nullify

  #has_many :assos, :through => :organizations, :dependent => :delete_all
  has_many :users #, :dependent => :nullify
  belongs_to :type_organization, :class_name => 'TypeOrganization', :foreign_key => 'type_organization_id'

  #named_scope :federati, :order => "#{User.table_name}.status = #{STATUS_ACTIVE}"
  #, :conditions => "#{User.table_name}.status = #{STATUS_ACTIVE}"

  #validation on uniqueness on two attributes
  validates_uniqueness_of :sigla, :scope => :type_organization_id
  #rails 3 validates :zipcode, :uniqueness => {:scope => :recorded_at}
  named_scope :cross_organizations_all_logos,
                :conditions => "#{CrossOrganization.table_name}.se_visibile = #{true} AND #{CrossOrganization.table_name}.image_file_name IS NOT NULL"
  ###NON USARE PIU organizzazione
  def to_s
    if (type_organization.nil?)
      'type(' + type_organization_id.to_s + ')? :: ' + (sigla.nil? ? "sigla?" : sigla) #to_s
    else
      type_organization.to_s + ' :: ' + (sigla.nil? ? "sigla?" : sigla) #to_s
    end
  end

  alias :name :to_s

  #ERROR fail to grab related table using  @cross_organization.organizations
  def organizations2
    Organization.find(:all, :conditions => ["cross_organization_id == ?", self.id.to_s]) #, :limit => 10)
  end

  def organization_for_user(user)
    asso_id = user.nil? ? -1 : user.asso_id
    #? non sense to filter by self.id. filter only by asso_id
    #Organization.find(:first, :conditions => ["cross_organization_id = :co_id AND asso_id = :asso_id", {
    #:co_id => self.id,
    #:asso_id => asso_id}]
    #)
    Organization.find(:first, :conditions => ["cross_organization_id = :co_id AND asso_id = :asso_id", {:co_id => self.id, :asso_id => asso_id}])
  end
end

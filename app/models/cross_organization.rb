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

  has_many :conventions#, :dependent => :nullify

  has_many :users #, :dependent => :nullify
  belongs_to :type_organization, :class_name => 'TypeOrganization', :foreign_key => 'type_organization_id'
  validates_uniqueness_of :sigla, :scope => :type_organization_id
  #rails 3 validates :zipcode, :uniqueness => {:scope => :recorded_at}
  named_scope :cross_organizations_all_logos,
                :conditions => "#{CrossOrganization.table_name}.se_visibile = #{true} AND #{CrossOrganization.table_name}.image_file_name IS NOT NULL"

  def to_s
    if self.type_organization.nil?
      'type? :: ' + (self.sigla.nil? ? "sigla?" : self.sigla) #to_s
    else
      self.type_organization.to_s + ' :: ' + (self.sigla.nil? ? "sigla?" : self.sigla) #to_s
    end
  end

  alias :name :to_s

end

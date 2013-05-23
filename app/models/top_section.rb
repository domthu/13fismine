class TopSection < ActiveRecord::Base
  has_attached_file :image,  :styles => {:xs => "32x32#", :s => "75x50#" , :m => "200x134#", :l => "300x200#"},
                    :url  => :url_image ,
                    :path => :path_image ,
                    :default_style => :l,
                    :default_url => "commons/:style_art-no-image.jpg"
  validates_attachment_size :image, :less_than => 200.kilobytes
  validates_attachment_content_type :image, :content_type => ['image/jpeg', 'image/png', 'image/gif', 'image/bmp']
 #validates_attachment_presence :image
  include FeesHelper  #Domthu  FeeConst
  has_many :sections, :foreign_key => 'top_section_id', :dependent => :nullify
  has_many :issues, :through => :sections
  belongs_to :top_menu, :class_name => 'TopMenu', :foreign_key => 'top_menu_id'

  #string
  validates_presence_of :sezione_top
  validates_uniqueness_of :sezione_top, :case_sensitive => false
  validates_length_of :sezione_top, :maximum => 100
  validates_presence_of :key , :maximum => 60

  #integer
  validates_presence_of :ordinamento
  validates_numericality_of :ordinamento, :allow_nil => true

  #boolean
  #validates_presence_of :se_visibile
  #validates_presence_of :hidden_menu
   #file
  #validates_presence_of :immagine

  #text-area? CSS? HTML area
  #validates_presence_of :key
  validates_length_of :key, :maximum => 4000

  named_scope :find_convegno, :conditions => "top_menu_id = " + FeeConst::TMENU_CONVEGNI.to_s

  def to_s
    sezione_top.to_s
  end

  alias :name :to_s
  private

  def url_image
    "commons/sections/:id:style_#{self.key}.:extension"
  end
  def path_image
    "#{RAILS_ROOT}/public/images/commons/sections/:id:style_#{self.key}.:extension"
  end

end

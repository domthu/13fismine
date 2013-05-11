class GroupBanner < ActiveRecord::Base
  has_attached_file :image, :styles => {:block_l => "256x216#", :block_s => "194x154#", :tramenu => "290x94#"},
                    :url => "commons/banners/:id:style.:extension",
                    :path => "#{RAILS_ROOT}/public/images/commons/banners/:id:style.:extension",
                    :default_url => "commons/:style_no-image.png"
  validates_attachment_size :image, :less_than => 200.kilobytes
  validates_attachment_content_type :image, :content_type => ['image/jpeg', 'image/png', 'image/gif', 'image/bmp']
  #domthu20120516
  #http://guides.rubyonrails.org/v2.3.8/association_basics.html#choosing-between-belongs-to-and-has-one
  #2.8 Choosing Between has_many :through and has_and_belongs_to_many
  has_many :cross_groups, :dependent => :nullify
  has_many :assos, :through => :cross_groups, :dependent => :delete_all

  #string
  validates_presence_of :espositore
  validates_uniqueness_of :espositore, :case_sensitive => false
  validates_length_of :espositore, :maximum => 255

  #integer
  validates_presence_of :priorita
  validates_numericality_of :priorita, :allow_nil => false
  named_scope :banners_tramenu,
              :conditions => "#{GroupBanner.table_name}.se_visibile = #{true} AND #{GroupBanner.table_name}.image_file_name IS NOT NULL AND #{GroupBanner.table_name}.posizione = 'tramenu'"
  named_scope :banners_block_l,
              :conditions => "#{GroupBanner.table_name}.se_visibile = #{true} AND #{GroupBanner.table_name}.image_file_name IS NOT NULL AND #{GroupBanner.table_name}.posizione = 'block_l'"
  named_scope :banners_block_s,
              :conditions => "#{GroupBanner.table_name}.se_visibile = #{true} AND #{GroupBanner.table_name}.image_file_name IS NOT NULL AND #{GroupBanner.table_name}.posizione = 'block_s'"
  #boolean
  #validates_presence_of :se_visibile

  #text-area? CSS? HTML area
  #validates_length_of :didascalia, :maximum => 4000

  def to_s
    espositore.to_s
  end

  alias :name :to_s

end

class GroupBanner < ActiveRecord::Base
  has_attached_file :image, :styles => {:block_l => "256x215#", :block_s => "194x154#", :tramenu => "290x94#"},
                    :url => "commons/banners/:id:style.:extension",
                    :path => "#{RAILS_ROOT}/public/images/commons/banners/:id:style.:extension",
                    :default_url => "commons/blankimage.png"
  validates_attachment_size :image, :less_than => 300.kilobytes
  validates_attachment_content_type :image, :content_type => ['image/jpeg', 'image/png', 'image/gif', 'image/bmp']
  belongs_to :convention, :class_name => 'Convention'
  validates_presence_of :espositore , :posizione
  # validates_uniqueness_of :espositore, :case_sensitive => false
  validates_length_of :espositore, :maximum => 255
  # scope per i banner nel fe
  named_scope :banners_tramenu,
              :conditions => "#{GroupBanner.table_name}.visibile_web = #{true} AND #{GroupBanner.table_name}.image_file_name IS NOT NULL AND #{GroupBanner.table_name}.posizione = 'tramenu'"
  named_scope :banners_block_l,
              :conditions => "#{GroupBanner.table_name}.visibile_web = #{true} AND #{GroupBanner.table_name}.image_file_name IS NOT NULL AND #{GroupBanner.table_name}.posizione = 'block_l'"
  named_scope :banners_block_s,
              :conditions => "#{GroupBanner.table_name}.visibile_web = #{true} AND #{GroupBanner.table_name}.image_file_name IS NOT NULL AND #{GroupBanner.table_name}.posizione = 'block_s'"

  def to_s
    espositore.to_s
  end

  alias :name :to_s

end

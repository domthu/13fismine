class Section < ActiveRecord::Base
  include FeesHelper
  has_attached_file :image, :styles => {:xs => "32x32#", :s => "75x50#", :m => "200x134#", :l => "300x200#"},
                    :default_style => :l,
                    :url => :url_image_sec,
                    :path => :path_image_sec,
                    :default_url => "commons/:style_art-no-image.jpg"
  validates_attachment_size :image, :less_than => 200.kilobytes
  validates_attachment_content_type :image, :content_type => ['image/jpeg', 'image/png', 'image/gif', 'image/bmp']

  #domthu20120516
  belongs_to :top_section, :class_name => 'TopSection', :foreign_key => 'top_section_id'
  #has_many :issues, :dependent => :nullify
  has_many :issues, :foreign_key => 'section_id', :dependent => :nullify

  #String
  validates_presence_of :sezione
  validates_uniqueness_of :sezione, :case_sensitive => false
  validates_length_of :sezione, :maximum => 100

  #integer
  validates_presence_of :ordinamento
  validates_numericality_of :ordinamento, :allow_nil => true

  named_scope :all_with_topsection, :include => :top_section, :order => "#{TopSection.table_name}.sezione_top, #{Section.table_name}.sezione"

  #TMENU_CONVEGNI = 9
  named_scope :all_convegni,
              :include => [{:top_section, :top_menu}],
              :conditions => "#{TopMenu.table_name}.id = '#{FeeConst::TMENU_CONVEGNI}'",
              :order => "#{TopSection.table_name}.sezione_top, #{Section.table_name}.sezione"

  #TMENU_QUESITI = 7
  named_scope :all_quesiti,
              :include => [{:top_section, :top_menu}],
              :conditions => "#{TopMenu.table_name}.id = '#{FeeConst::TMENU_QUESITI}'",
              :order => "#{TopSection.table_name}.sezione_top, #{Section.table_name}.sezione"

  def to_s
    sezione
  end

  alias :name :to_s

  def full_name
    if self.top_section.nil?
      if self.sezione.nil?
        ''
      else
        sezione
      end
    else
      if  top_section.to_s == sezione
        sezione
      else
        top_section.to_s + " :: " + sezione
      end
    end
  end
  def select_full_name
    if self.top_section.nil?
      if self.sezione.nil?
        ''
      else
        sezione
      end
    else
      if  top_section.to_s == sezione
        sezione
      else
        if self.protetto
        top_section.to_s + ' :: ' + sezione  + ' *'
        else
          top_section.to_s + " :: " + sezione
        end
      end
    end
  end

  def url_image_sec
    "commons/sections/#{self.top_section_id}:style_:id.:extension"
  end

  def path_image_sec
    "#{RAILS_ROOT}/public/images/commons/sections/#{self.top_section_id}:style_:id.:extension"
  end

end

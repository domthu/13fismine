class TopSection < ActiveRecord::Base

  #domthu20120516
  has_many :sections, :dependent => :destroy
  has_many :issues, :through => :sections

  #string
  validates_presence_of :sezione_top
  validates_uniqueness_of :sezione_top, :case_sensitive => false
  validates_length_of :sezione_top, :maximum => 100

  #integer
  validates_presence_of :ordinamento
  validates_numericality_of :ordinamento, :allow_nil => true

  #boolean
  #validates_presence_of :se_visibile

  #file
  #validates_presence_of :immagine

  #text-area? CSS? HTML area
  #validates_presence_of :style
  validates_length_of :style, :maximum => 4000

  def to_s
    sezione_top.to_s
  end

  alias :name :to_s

end

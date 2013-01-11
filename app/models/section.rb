class Section < ActiveRecord::Base

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

  def to_s
    sezione.to_s
  end

  alias :name :to_s

end

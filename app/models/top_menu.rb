class TopMenu < ActiveRecord::Base

  has_many :top_sections, :foreign_key => 'top_menu_id', :dependent => :nullify
  has_many :sections, :through => :top_sections
  has_many :issues, :through => :sections

  #string
  validates_presence_of :description, :order
  validates_uniqueness_of :description, :case_sensitive => false
  validates_length_of :description, :maximum => 100

  #integer
  validates_presence_of :order
  validates_numericality_of :order, :allow_nil => false, :default => 1

#  #rewrite url
#  def to_param
#    "/session/#{self.id}"
#    #"#{self.id}-#{self.title.gsub(/[^a-z0-9]+/i, '-').gsub(/-{2}/, '-').gsub(/-$/, '')}"
#  end
end

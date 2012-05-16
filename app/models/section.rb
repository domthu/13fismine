class Section < ActiveRecord::Base

  #domthu20120516
  belongs_to :top_section, :class_name => 'TopSection', :foreign_key => 'top_section_id'
  has_many :issues, :dependent => :nullify

end

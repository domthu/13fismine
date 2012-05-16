class TopSection < ActiveRecord::Base

  #domthu20120516
  has_many :sections, :dependent => :destroy

end

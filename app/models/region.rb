class Region < ActiveRecord::Base

  #domthu20120516
  #http://guides.rubyonrails.org/association_basics.html
  has_many :organizations, :dependent => :nullify
  has_many :provinces, :dependent => :destroy

end

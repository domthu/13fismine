class GroupBanner < ActiveRecord::Base

  #domthu20120516
  #http://guides.rubyonrails.org/v2.3.8/association_basics.html#choosing-between-belongs-to-and-has-one
  #2.8 Choosing Between has_many :through and has_and_belongs_to_many
  has_many :cross_groups, :dependent => :nullify
  has_many :assos, :through => :cross_group, :dependent => :delete_all

end

class Asso < ActiveRecord::Base

  #domthu20120516
  has_many :users  #, :dependent => :destroy
  has_many :organizations  #, :dependent => :destroy
  #http://guides.rubyonrails.org/v2.3.8/association_basics.html#choosing-between-belongs-to-and-has-one
  #2.8 Choosing Between has_many :through and has_and_belongs_to_many
  has_many :cross_groups, :dependent => :nullify
  has_many :group_banners, :through => :cross_group, :dependent => :delete

end

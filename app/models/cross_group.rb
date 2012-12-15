class CrossGroup < ActiveRecord::Base

  #domthu20120516
  #http://guides.rubyonrails.org/v2.3.8/association_basics.html#choosing-between-belongs-to-and-has-one
  #2.8 Choosing Between has_many :through and has_and_belongs_to_many
  belongs_to :asso 
  belongs_to :group_banner
  validates_presence_of :asso
  validates_presence_of :group_banner

  #boolean
  validates_presence_of :se_visibile

  def to_s
    asso.name + ' ' + group_banner.name
  end

  alias :name :to_s

end

#You need to define the join model as a separate association when using has_many :through:
#class Post < ActiveRecord::Base
#  has_many :user_posts
#  has_many :users, :through => :user_posts
#class User < ActiveRecord::Base
#  has_many :user_posts
#  has_many :posts, :through => :user_posts
#class UserPost < ActiveRecord::Base
#  belongs_to :user # foreign_key is user_id
#  belongs_to :post # foreign_key is post_id
#This works best when you need to keep data that pertains to the join model itself, or if you want to perform validations on the join separate from the other two models.

#If you just want a simple join table, it's easier to use the old HABTM syntax:
#class User < ActiveRecord::Base
#  has_and_belongs_to_many :posts
#class Post < ActiveRecord::Base
#  has_and_belongs_to_many :users



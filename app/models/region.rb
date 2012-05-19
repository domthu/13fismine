class Region < ActiveRecord::Base

  #domthu20120516
  #http://guides.rubyonrails.org/association_basics.html
  has_many :organizations, :dependent => :nullify
  has_many :provinces, :dependent => :destroy

  #Custom find or create  self.find_by_id_or_create
  class ActiveRecord::Base
    def self.find_by_id_or_create(id, &block)
      obj = self.find_by_id( id ) || self.new
      yield obj
      obj.save
    end
  end

##Use as this
#Category.find_by_id_or_create(10) do |c|
#   c.name = "My new name"
#end


end

class Reservation < ActiveRecord::Base
  belongs_to :issue
end

public
def is_reserved(iid, uid=User.current )
 return nil if iid.nil? || uid.nil?
 @res =  self.find(:first, :conditions => ["user_id = :uid", {:uid => User.current}, "AND issue_id = :iid", {:iid => @convegno.id}])
return false if @res.count == 0
end
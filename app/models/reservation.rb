class Reservation < ActiveRecord::Base
  belongs_to :issue
  belongs_to :user

  def to_s
    self.user.login + " del " + format_date(self.updated_at)
  end


  def is_reserved(issue_id, user_id=User.current.id)
   return nil if iid.nil? || uid.nil?
   @res =  self.find(:first, :conditions => ["user_id = :uid", {:uid => user_id}, "AND issue_id = :iid", {:iid => issue_id}])
    return (@res.count > 0)
  end

end

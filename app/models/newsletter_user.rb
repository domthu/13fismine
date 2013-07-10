class NewsletterUser < ActiveRecord::Base

  belongs_to :user
  belongs_to :project
  validates_length_of :email_type, :maximum => 30

  validates_uniqueness_of :user_id, :scope => :project_id

  #boolean
  validates_presence_of :sended

  #named scope
  #scope :per_user, -> (usr_id) { where("user_id < ?", usr_id) } Rails 3?
  #dynamic scope\
  #NewsletterUser.scoped_by_user_id(12)

  def to_s
    s = ''
    s += (user.nil? ? "?(user)" : user.name)
    s += (project.nil? ? "?(news)" : project.name)
    return (s.nil? || s.blank?)  ? "-" : s
  end

  alias :name :to_s

  def have_project?
    return !self.project_id.nil?
  end
end
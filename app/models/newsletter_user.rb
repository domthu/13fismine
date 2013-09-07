class NewsletterUser < ActiveRecord::Base

  belongs_to :user
  belongs_to :convention
  #belongs_to :project accross newsletter
  belongs_to :newsletter
  validates_length_of :email_type, :maximum => 30

  #se voglio re-inviare --> buttare sended a false
  validates_uniqueness_of :user_id, :scope => :newsletter_id #&email_type='newsletter'

  #boolean
  #validates_presence_of :sended No di default 0 = false

  #named scope
  #scope :per_user, -> (usr_id) { where("user_id < ?", usr_id) } Rails 3?
  #dynamic scope\
  #NewsletterUser.scoped_by_user_id(12)

  def to_s
    s = ''
    s += (user.nil? ? "?(user)" : user.name)
    s += (newsletter.nil? ? "?(news)" : newsletter.name)
    return (s.nil? || s.blank?)  ? "-" : s
  end

  alias :name :to_s

  def have_convention?
    if self.convention_id && self.convention.nil?
      #verificare che non è stato eliminato la convention
      #if Convention.where(:user_id => current_user.id).blank?
      if Convention.exists?(self.convention_id)
        self.convention = Convention.find_by_id(self.convention_id)
      else
        self.convention_id = nil
        self.save!
      end
    end
    return self.convention_id.nil?
  end

  def have_newsletter?
    return !self.newsletter_id.nil?
  end

  def have_project?
    return self.have_newsletter? && !self.newsletter.project_id.nil?
  end
end

class NewsletterArchive < ActiveRecord::Base

  belongs_to :email_type
  belongs_to :user
  belongs_to :convention
  belongs_to :newsletter
  belongs_to :information, :dependent => :destroy

  def to_s
    s = ''
    s += (user.nil? ? "?(user)" : user.name)
    s += (newsletter.nil? ? "?(news)" : newsletter.name)
    return (s.nil? || s.blank?)  ? "-" : s
  end

  alias :name :to_s

  def errore
    if self.information.nil? || self.information.description.blank?
      ""
    else
      self.information.description
    end
  end

  def errore_abbrv
    if self.information.nil? || self.information.description.blank?
      ""
    else
      truncate(self.information.description, :length => 100, omission: '...')
    end
  end

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

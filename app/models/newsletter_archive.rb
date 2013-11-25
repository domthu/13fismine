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

  def have_error?
    if self.information_id && self.information && !self.information.description.blank?
      true
    else
      false
    end
  end

  def errore
    if have_error?
      self.information.description
    else
      ""
    end
  end

  def errore_abbrv
    if have_error?
      truncate(self.information.description, :length => 100, :omission => '...')
    else
      ""
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

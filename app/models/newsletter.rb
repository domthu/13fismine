class Newsletter < ActiveRecord::Base

  belongs_to :project
  has_many :newsletter_users, :dependent => :delete_all #destroy

  validates_uniqueness_of :project_id#, :scope => :project_id

  #boolean
  validates_inclusion_of :sended, :in => [true, false]

  #named scope
  #scope :per_project, ->(prj_id) { where("project_id < ?", prj_id) } Rails 3?
  #dynamic scope
  #Newsletter.scoped_by_project_id(12)

  def to_s
    (project.nil? ? "?(news)" : project.name)
  end

  alias :name :to_s

  def self.find_by_project(project_id)
    find(:first, :conditions => ["project_id = ?", project_id])
  end

  def have_emails_to_send?
    return (self && self.newsletter_users.any? && self.newsletter_users.count(:conditions => ['sended = false AND (errore is null OR LENGTH(errore) = 0)']) > 0)
  end

  def emails_pending
    return (self.have_emails_to_send?) ? (self.newsletter_users.count(:conditions => ['sended = false AND (errore is null OR LENGTH(errore) = 0)'])) : 0;
  end

end

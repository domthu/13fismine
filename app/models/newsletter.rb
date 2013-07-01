class Newsletter < ActiveRecord::Base

  belongs_to :project
  has_many :newsletter_users, :dependent => :delete_all

  validates_uniqueness_of :project_id#, :scope => :project_id

  #boolean
  #validates_presence_of :sended

  def to_s
    (project.nil? ? "?(news)" : project.name)
  end

  alias :name :to_s

  def self.find_by_project(project_id)
    find(:first, :conditions => ["project_id = ?", project_id])
  end

end

# Redmine - project management software
# Copyright (C) 2006-2011  Created by  DomThual & SPecchiaSoft (2013)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

class Project < ActiveRecord::Base
  include Redmine::SafeAttributes
  include ActionView::Helpers::TextHelper
  include FeesHelper #Domthu  FeeConst
                     # Project statuses
  STATUS_ACTIVE = 1
  STATUS_ARCHIVED = 9
                     #domthu verificare i status possibily dentro la gestione amministrazione
  STATUS_FS = 99

  # Maximum length for project identifiers
  IDENTIFIER_MAX_LENGTH = 100

  # Specific overidden Activities
  has_many :time_entry_activities
  has_many :members, :include => [:user, :roles], :conditions => "#{User.table_name}.type='User' AND #{User.table_name}.status=#{User::STATUS_ACTIVE}"
  has_many :memberships, :class_name => 'Member'
  has_many :member_principals, :class_name => 'Member',
           :include => :principal,
           :conditions => "#{Principal.table_name}.type='Group' OR (#{Principal.table_name}.type='User' AND #{Principal.table_name}.status=#{User::STATUS_ACTIVE})"
  has_many :users, :through => :members
  has_many :principals, :through => :member_principals, :source => :principal

  has_many :enabled_modules, :dependent => :delete_all
  has_and_belongs_to_many :trackers, :order => "#{Tracker.table_name}.position"
  has_many :issues, :dependent => :destroy, :order => "#{Issue.table_name}.created_on DESC", :include => [:status, :tracker, {:section => :top_section}]
  has_many :issue_changes, :through => :issues, :source => :journals
  has_many :versions, :dependent => :destroy, :order => "#{Version.table_name}.effective_date DESC, #{Version.table_name}.name DESC"
  has_many :time_entries, :dependent => :delete_all
  has_many :queries, :dependent => :delete_all
  has_many :documents, :dependent => :destroy
  has_many :news, :dependent => :destroy, :include => :author
  has_many :issue_categories, :dependent => :delete_all, :order => "#{IssueCategory.table_name}.name"
  has_many :boards, :dependent => :destroy, :order => "position ASC"
  has_one :repository, :dependent => :destroy
  has_many :changesets, :through => :repository
  has_one :wiki, :dependent => :destroy
  # Custom field for the project issues
  has_and_belongs_to_many :issue_custom_fields,
                          :class_name => 'IssueCustomField',
                          :order => "#{CustomField.table_name}.position",
                          :join_table => "#{table_name_prefix}custom_fields_projects#{table_name_suffix}",
                          :association_foreign_key => 'custom_field_id'

  #domthu20120516
  #migration AddFieldsToProject titolo:string data_dal:datetime data_al:datetime search_key:string

  acts_as_nested_set :order => 'name', :dependent => :destroy
  acts_as_attachable :view_permission => :view_files,
                     :delete_permission => :manage_files

  acts_as_customizable
  acts_as_searchable :columns => ['name', 'identifier', 'description', 'search_key'], :project_key => 'id', :permission => nil
  acts_as_event :title => Proc.new { |o| "#{l(:label_project)}: #{o.name}" },
                :url => Proc.new { |o| {:controller => 'projects', :action => 'show', :id => o} },
                :author => nil

  attr_protected :status

  validates_presence_of :name, :identifier
  validates_uniqueness_of :identifier
  validates_associated :repository, :wiki
  validates_length_of :name, :maximum => 255
  validates_length_of :homepage, :maximum => 255
  validates_length_of :identifier, :in => 1..IDENTIFIER_MAX_LENGTH
  # donwcase letters, digits, dashes but not digits only
  validates_format_of :identifier, :with => /^(?!\d+$)[a-z0-9\-]*$/, :if => Proc.new { |p| p.identifier_changed? }
  # reserved words
  validates_exclusion_of :identifier, :in => %w( new )

  before_destroy :delete_all_members

  named_scope :has_module, lambda { |mod| {:conditions => ["#{Project.table_name}.id IN (SELECT em.project_id FROM #{EnabledModule.table_name} em WHERE em.name=?)", mod.to_s]} }
  named_scope :active, {:conditions => "#{Project.table_name}.status = #{STATUS_ACTIVE}"}
  named_scope :all_public, {:conditions => {:is_public => true}}
  #domthu
  named_scope :all_public_fs, {:conditions => ['is_public = true AND identifier LIKE ?', "#{FeeConst::EDIZIONE_KEY}%"], :order => "#{table_name}.created_on DESC"}
  named_scope :visible, lambda { |*args| {:conditions => Project.visible_condition(args.shift || User.current, *args)} }

#  def to_s
#    str = "[" << self.id.to_s << "] "
#    str << (self.ragione_sociale.blank?  ? "?" : self.ragione_sociale)
#    str << (self.presidente.blank? ? "" : " (" + self.presidente + ")")
#    return str
#  end

  #TODO
  def is_public_fs?
    self.is_public == true #&& self.promoted_to_front_page == true
  end

  # Returns true if the project is visible to +user+ or to the current user.
  def visible?(user=User.current)
    user.allowed_to?(:view_project, self)
  end


  def initialize(attributes = nil)
    super

    initialized = (attributes || {}).stringify_keys
    if !initialized.key?('identifier') && Setting.sequential_project_identifiers?
      self.identifier = Project.next_identifier
    end
    if !initialized.key?('is_public')
      self.is_public = Setting.default_projects_public?
    end
    if !initialized.key?('enabled_module_names')
      self.enabled_module_names = Setting.default_projects_modules
    end
    if !initialized.key?('trackers') && !initialized.key?('tracker_ids')
      self.trackers = Tracker.all
    end
  end

  def identifier=(identifier)
    super unless identifier_frozen?
  end

  def identifier_frozen?
    errors[:identifier].nil? && !(new_record? || identifier.blank?)
  end

  # returns latest created projects
  # non public projects will be returned only if user is a member of those
  def self.latest(user=nil, count=5)
    visible(user).find(:all, :limit => count, :order => "created_on DESC")
  end

  # returns all projects for public area
  def self.all_fs(user = User.current)
    #:conditions => [ "catchment_areas_id = ?", params[:id]]
    #find(:all, :conditions => "#{table_name}.is_public = 1", :order => "#{table_name}.created_on DESC")
    all_public_fs.all
  end

  # returns limited latest projects for homepage in public area
  # MariaCristina creare flag .promoted_to_front_page, per il momento usiamo .is_public combinato con .status
  def self.latest_fs(user = User.current, count = 5)
    #:conditions => [... AND #{table_name}.status = #{STATUS_FS}"]
    all_public_fs.all(:limit => count)
    #raggionare su come fare: STATUS_ARCHIVED o allora creare un flag per publicazione in home page
    #Il STATUS_FS dovrebbe essere presso quando la newsletter viene inviata
  end

  #Generate the newsletter, program to send it, set project status to FS
  def self.send_newsletter(user = User.current)
    #creare tabella di invio
    #reccuperare l'html da un template senza la personalizzazione per utente
    #salvare su una tabella di invio (con destinatari?)

    # MOTORE Gestisce gli invi

    self.promoted_to_front_page = true
    self.status = STATUS_FS #raggionare su come fare: STATUS_ARCHIVED o allora creare un flag per publicazione in home page
    save
  end

  def self.find_public(id = 0, user = User.current)
    #@edizione = Project.find(params[:id])
    #Project.find(:first, :conditions
    #Project.find_by_id(id)
    #search(id,:conditions => "#{table_name}.is_public = 1 AND #{table_name}.status IN ( #{STATUS_ARCHIVED}, #{STATUS_FS} )", :include => :role)
    #control user => Non fare. il controllo avviene per gli articoli in modo da incentivare l'abbonamento
    #if user.nil? || !user.isauthored
    #  return nil
    #else
    prj = find(id)
    if prj && !prj.is_public
      return nil
    else
      return prj
    end
    #end
  end

  def self.exists_row_quesiti

    # p=  Project.find_or_initialize_by_id(1).first_or_create(:id => 1 , :name => 'QUESITI', :identifier => 'quesiti', :status => 1, :is_public => 0, :description => 'Contenitore di sistema per quesiti')
#    prj = Project.find_or_initialize_by_id(FeeConst::QUESITO_ID) do |p|
#      p.id = FeeConst::QUESITO_ID,
#      p.name = 'QUESITI',
#      p.identifier = FeeConst::QUESITO_KEY,
#      p.status = 1,
#      p.is_public = 0,
#      p.description = 'Contenitore di sistema per quesiti',
#      p.data_dal = Date.today
#      p.data_al = Date.today + (365 * 100)
#      p.save!
#    end
    p = Project.find_or_initialize_by_id(FeeConst::QUESITO_ID)
    if p.new_record?
      p.members
      p.id = FeeConst::QUESITO_ID,
      p.name = 'QUESITI',
      p.identifier = FeeConst::QUESITO_KEY,
      p.status = 1,
      p.is_public = 0,
      p.description = 'Contenitore di sistema per quesiti',
      p.data_dal = Date.today
      p.data_al = Date.today + (365 * 100)
      p.save!
      p.members_fs_add_author_manager(nil, nil)
    end
  end

  def members_fs_add_author_manager(_managers, _authors)
    #begin
    #Domthu Add all collaboratori as a project members
    #user.role_id = Redattore
    _managers = User.all(:conditions => {:role_id => FeeConst::ROLE_MANAGER, :admin => false }) if _managers.nil?
    _authors = User.all(:conditions => {:role_id => FeeConst::ROLE_AUTHOR, :admin => false}) if _authors.nil?
    #puts "***********MANAGER*****************************"
    #puts _managers
    for usr in _managers
      member = Member.new
      member.user = usr
      #3 	Manager
      #member.roles = [Role.find_by_name('Manager')]
      member.roles = [Role.find_by_id(FeeConst::ROLE_MANAGER)]
      #ActiveRecord::RecordInvalid (Validation failed: Ruolo non è valido):
      self.members << member
    end
    #puts "***********AUTHORS*****************************"
    #puts _authors
    for usr in _authors
      member = Member.new
      member.user = usr
      #4 	Redattore
      #member.roles = [Role.find_by_name('Redattore')]
      member.roles = [Role.find_by_id(FeeConst::ROLE_AUTHOR)]
      self.members << member
    end
    #puts "***********************************************"
    #rescue
  end
  # Returns a SQL conditions string used to find all projects visible by the specified user.
  #
  # Examples:
  #   Project.visible_condition(admin)        => "projects.status = 1"
  #   Project.visible_condition(normal_user)  => "((projects.status = 1) AND (projects.is_public = 1 OR projects.id IN (1,3,4)))"
  #   Project.visible_condition(anonymous)    => "((projects.status = 1) AND (projects.is_public = 1))"
  def self.visible_condition(user, options={})
    allowed_to_condition(user, :view_project, options)
  end

  # Returns a SQL conditions string used to find all projects for which +user+ has the given +permission+
  #
  # Valid options:
  # * :project => limit the condition to project
  # * :with_subprojects => limit the condition to project and its subprojects
  # * :member => limit the condition to the user projects
  def self.allowed_to_condition(user, permission, options={})
    base_statement = "#{Project.table_name}.status=#{Project::STATUS_ACTIVE}"
    if perm = Redmine::AccessControl.permission(permission)
      unless perm.project_module.nil?
        # If the permission belongs to a project module, make sure the module is enabled
        base_statement << " AND #{Project.table_name}.id IN (SELECT em.project_id FROM #{EnabledModule.table_name} em WHERE em.name='#{perm.project_module}')"
      end
    end
    if options[:project]
      project_statement = "#{Project.table_name}.id = #{options[:project].id}"
      project_statement << " OR (#{Project.table_name}.lft > #{options[:project].lft} AND #{Project.table_name}.rgt < #{options[:project].rgt})" if options[:with_subprojects]
      base_statement = "(#{project_statement}) AND (#{base_statement})"
    end

    if user.admin?
      base_statement
    else
      statement_by_role = {}
      unless options[:member]
        role = user.logged? ? Role.non_member : Role.anonymous
        if role.allowed_to?(permission)
          statement_by_role[role] = "#{Project.table_name}.is_public = #{connection.quoted_true}"
        end
      end
      if user.logged?
        user.projects_by_role.each do |role, projects|
          if role.allowed_to?(permission)
            statement_by_role[role] = "#{Project.table_name}.id IN (#{projects.collect(&:id).join(',')})"
          end
        end
      end
      if statement_by_role.empty?
        "1=0"
      else
        if block_given?
          statement_by_role.each do |role, statement|
            if s = yield(role, user)
              statement_by_role[role] = "(#{statement} AND (#{s}))"
            end
          end
        end
        "((#{base_statement}) AND (#{statement_by_role.values.join(' OR ')}))"
      end
    end
  end

  # Returns the Systemwide and project specific activities
  def activities(include_inactive=false)
    if include_inactive
      return all_activities
    else
      return active_activities
    end
  end

  # Will create a new Project specific Activity or update an existing one
  #
  # This will raise a ActiveRecord::Rollback if the TimeEntryActivity
  # does not successfully save.
  def update_or_create_time_entry_activity(id, activity_hash)
    if activity_hash.respond_to?(:has_key?) && activity_hash.has_key?('parent_id')
      self.create_time_entry_activity_if_needed(activity_hash)
    else
      activity = project.time_entry_activities.find_by_id(id.to_i)
      activity.update_attributes(activity_hash) if activity
    end
  end

  # Create a new TimeEntryActivity if it overrides a system TimeEntryActivity
  #
  # This will raise a ActiveRecord::Rollback if the TimeEntryActivity
  # does not successfully save.
  def create_time_entry_activity_if_needed(activity)
    if activity['parent_id']

      parent_activity = TimeEntryActivity.find(activity['parent_id'])
      activity['name'] = parent_activity.name
      activity['position'] = parent_activity.position

      if Enumeration.overridding_change?(activity, parent_activity)
        project_activity = self.time_entry_activities.create(activity)

        if project_activity.new_record?
          raise ActiveRecord::Rollback, "Overridding TimeEntryActivity was not successfully saved"
        else
          self.time_entries.update_all("activity_id = #{project_activity.id}", ["activity_id = ?", parent_activity.id])
        end
      end
    end
  end

  # Returns a :conditions SQL string that can be used to find the issues associated with this project.
  #
  # Examples:
  #   project.project_condition(true)  => "(projects.id = 1 OR (projects.lft > 1 AND projects.rgt < 10))"
  #   project.project_condition(false) => "projects.id = 1"
  def project_condition(with_subprojects)
    cond = "#{Project.table_name}.id = #{id}"
    cond = "(#{cond} OR (#{Project.table_name}.lft > #{lft} AND #{Project.table_name}.rgt < #{rgt}))" if with_subprojects
    cond
  end

  def self.find(*args)
    if args.first && args.first.is_a?(String) && !args.first.match(/^\d*$/)
      project = find_by_identifier(*args)
      raise ActiveRecord::RecordNotFound, "Couldn't find Project with identifier=#{args.first}" if project.nil?
      project
    else
      super
    end
  end

  def to_param
    # id is used for projects with a numeric identifier (compatibility)
    @to_param ||= (identifier.to_s =~ %r{^\d*$} ? id.to_s : identifier)
  end

  def active?
    self.status == STATUS_ACTIVE
  end

  #TODO
  def promoted_to_front_page?
    #quando si pubblica la newsletter il sistema dovrà impostare status == STATUS_FS e is_public == true
    self.status == STATUS_FS
  end

  def archived?
    self.status == STATUS_ARCHIVED
  end

  # Archives the project and its descendants
  def archive
    # Check that there is no issue of a non descendant project that is assigned
    # to one of the project or descendant versions
    v_ids = self_and_descendants.collect { |p| p.version_ids }.flatten
    if v_ids.any? && Issue.find(:first, :include => :project,
                                :conditions => ["(#{Project.table_name}.lft < ? OR #{Project.table_name}.rgt > ?)" +
                                                    " AND #{Issue.table_name}.fixed_version_id IN (?)", lft, rgt, v_ids])
      return false
    end
    Project.transaction do
      archive!
    end
    true
  end

  # Unarchives the project
  # All its ancestors must be active
  def unarchive
    return false if ancestors.detect { |a| !a.active? }
    update_attribute :status, STATUS_ACTIVE
  end

  # Returns an array of projects the project can be moved to
  # by the current user
  def allowed_parents
    return @allowed_parents if @allowed_parents
    @allowed_parents = Project.find(:all, :conditions => Project.allowed_to_condition(User.current, :add_subprojects))
    @allowed_parents = @allowed_parents - self_and_descendants
    if User.current.allowed_to?(:add_project, nil, :global => true) || (!new_record? && parent.nil?)
      @allowed_parents << nil
    end
    unless parent.nil? || @allowed_parents.empty? || @allowed_parents.include?(parent)
      @allowed_parents << parent
    end
    @allowed_parents
  end

  # Sets the parent of the project with authorization check
  def set_allowed_parent!(p)
    unless p.nil? || p.is_a?(Project)
      if p.to_s.blank?
        p = nil
      else
        p = Project.find_by_id(p)
        return false unless p
      end
    end
    if p.nil?
      if !new_record? && allowed_parents.empty?
        return false
      end
    elsif !allowed_parents.include?(p)
      return false
    end
    set_parent!(p)
  end

  # Sets the parent of the project
  # Argument can be either a Project, a String, a Fixnum or nil
  def set_parent!(p)
    unless p.nil? || p.is_a?(Project)
      if p.to_s.blank?
        p = nil
      else
        p = Project.find_by_id(p)
        return false unless p
      end
    end
    if p == parent && !p.nil?
      # Nothing to do
      true
    elsif p.nil? || (p.active? && move_possible?(p))
      # Insert the project so that target's children or root projects stay alphabetically sorted
      sibs = (p.nil? ? self.class.roots : p.children)
      to_be_inserted_before = sibs.detect { |c| c.name.to_s.downcase > name.to_s.downcase }
      if to_be_inserted_before
        move_to_left_of(to_be_inserted_before)
      elsif p.nil?
        if sibs.empty?
          # move_to_root adds the project in first (ie. left) position
          move_to_root
        else
          move_to_right_of(sibs.last) unless self == sibs.last
        end
      else
        # move_to_child_of adds the project in last (ie.right) position
        move_to_child_of(p)
      end
      Issue.update_versions_from_hierarchy_change(self)
      true
    else
      # Can not move to the given target
      false
    end
  end

  # Returns an array of the trackers used by the project and its active sub projects
  def rolled_up_trackers
    @rolled_up_trackers ||=
        Tracker.find(:all, :joins => :projects,
                     :select => "DISTINCT #{Tracker.table_name}.*",
                     :conditions => ["#{Project.table_name}.lft >= ? AND #{Project.table_name}.rgt <= ? AND #{Project.table_name}.status = #{STATUS_ACTIVE}", lft, rgt],
                     :order => "#{Tracker.table_name}.position")
  end

  # Closes open and locked project versions that are completed
  def close_completed_versions
    Version.transaction do
      versions.find(:all, :conditions => {:status => %w(open locked)}).each do |version|
        if version.completed?
          version.update_attribute(:status, 'closed')
        end
      end
    end
  end

  # Returns a scope of the Versions on subprojects
  def rolled_up_versions
    @rolled_up_versions ||=
        Version.scoped(:include => :project,
                       :conditions => ["#{Project.table_name}.lft >= ? AND #{Project.table_name}.rgt <= ? AND #{Project.table_name}.status = #{STATUS_ACTIVE}", lft, rgt])
  end

  # Returns a scope of the Versions used by the project
  def shared_versions
    if new_record?
      Version.scoped(:include => :project,
                     :conditions => "#{Project.table_name}.status = #{Project::STATUS_ACTIVE} AND #{Version.table_name}.sharing = 'system'")
    else
      @shared_versions ||= begin
        r = root? ? self : root
        Version.scoped(:include => :project,
                       :conditions => "#{Project.table_name}.id = #{id}" +
                           " OR (#{Project.table_name}.status = #{Project::STATUS_ACTIVE} AND (" +
                           " #{Version.table_name}.sharing = 'system'" +
                           " OR (#{Project.table_name}.lft >= #{r.lft} AND #{Project.table_name}.rgt <= #{r.rgt} AND #{Version.table_name}.sharing = 'tree')" +
                           " OR (#{Project.table_name}.lft < #{lft} AND #{Project.table_name}.rgt > #{rgt} AND #{Version.table_name}.sharing IN ('hierarchy', 'descendants'))" +
                           " OR (#{Project.table_name}.lft > #{lft} AND #{Project.table_name}.rgt < #{rgt} AND #{Version.table_name}.sharing = 'hierarchy')" +
                           "))")
      end
    end
  end

  # Returns a hash of project users grouped by role
  def users_by_role
    members.find(:all, :include => [:user, :roles]).inject({}) do |h, m|
      m.roles.each do |r|
        h[r] ||= []
        h[r] << m.user
      end
      h
    end
  end

  # Deletes all project's members
  def delete_all_members
    me, mr = Member.table_name, MemberRole.table_name
    connection.delete("DELETE FROM #{mr} WHERE #{mr}.member_id IN (SELECT #{me}.id FROM #{me} WHERE #{me}.project_id = #{id})")
    Member.delete_all(['project_id = ?', id])
  end

  # Users/groups issues can be assigned to
  def assignable_users
    assignable = Setting.issue_group_assignment? ? member_principals : members
    assignable.select { |m| m.roles.detect { |role| role.assignable? } }.collect { |m| m.principal }.sort
  end

  # Returns the mail adresses of users that should be always notified on project events
  def recipients
    notified_users.collect { |user| user.mail }
  end

  # Returns the users that should be notified on project events
  def notified_users
    # TODO: User part should be extracted to User#notify_about?
    members.select { |m| m.mail_notification? || m.user.mail_notification == 'all' }.collect { |m| m.user }
  end

  # Returns an array of all custom fields enabled for project issues
  # (explictly associated custom fields and custom fields enabled for all projects)
  def all_issue_custom_fields
    @all_issue_custom_fields ||= (IssueCustomField.for_all + issue_custom_fields).uniq.sort
  end

  # Returns an array of all custom fields enabled for project time entries
  # (explictly associated custom fields and custom fields enabled for all projects)
  def all_time_entry_custom_fields
    @all_time_entry_custom_fields ||= (TimeEntryCustomField.for_all + time_entry_custom_fields).uniq.sort
  end

  def project
    self
  end

  def <=>(project)
    name.downcase <=> project.name.downcase
  end

  def to_s
    name
  end

  # Returns a short description of the projects (first lines)
  def short_description(length = 255)
    description.gsub(/^(.{#{length}}[^\n\r]*).*$/m, '\1...').strip if description
  end

  def css_classes
    s = 'project'
    s << ' root' if root?
    s << ' child' if child?
    s << (leaf? ? ' leaf' : ' parent')
    s
  end

  # The earliest start date of a project, based on it's issues and versions
  def start_date
    [
        issues.minimum('start_date'),
        shared_versions.collect(&:effective_date),
        shared_versions.collect(&:start_date)
    ].flatten.compact.min
  end

  # The latest due date of an issue or version
  def due_date
    [
        issues.maximum('due_date'),
        shared_versions.collect(&:effective_date),
        shared_versions.collect { |v| v.fixed_issues.maximum('due_date') }
    ].flatten.compact.max
  end

  def overdue?
    active? && !due_date.nil? && (due_date < Date.today)
  end

  # Returns the percent completed for this project, based on the
  # progress on it's versions.
  def completed_percent(options={:include_subprojects => false})
    if options.delete(:include_subprojects)
      total = self_and_descendants.collect(&:completed_percent).sum

      total / self_and_descendants.count
    else
      if versions.count > 0
        total = versions.collect(&:completed_pourcent).sum

        total / versions.count
      else
        100
      end
    end
  end

  # Return true if this project is allowed to do the specified action.
  # action can be:
  # * a parameter-like Hash (eg. :controller => 'projects', :action => 'edit')
  # * a permission Symbol (eg. :edit_project)
  def allows_to?(action)
    if action.is_a? Hash
      allowed_actions.include? "#{action[:controller]}/#{action[:action]}"
    else
      allowed_permissions.include? action
    end
  end

  def module_enabled?(module_name)
    module_name = module_name.to_s
    enabled_modules.detect { |m| m.name == module_name }
  end

  def enabled_module_names=(module_names)
    if module_names && module_names.is_a?(Array)
      module_names = module_names.collect(&:to_s).reject(&:blank?)
      self.enabled_modules = module_names.collect { |name| enabled_modules.detect { |mod| mod.name == name } || EnabledModule.new(:name => name) }
    else
      enabled_modules.clear
    end
  end

  # Returns an array of the enabled modules names
  def enabled_module_names
    enabled_modules.collect(&:name)
  end

  # Enable a specific module
  #
  # Examples:
  #   project.enable_module!(:issue_tracking)
  #   project.enable_module!("issue_tracking")
  def enable_module!(name)
    enabled_modules << EnabledModule.new(:name => name.to_s) unless module_enabled?(name)
  end

  # Disable a module if it exists
  #
  # Examples:
  #   project.disable_module!(:issue_tracking)
  #   project.disable_module!("issue_tracking")
  #   project.disable_module!(project.enabled_modules.first)
  def disable_module!(target)
    target = enabled_modules.detect { |mod| target.to_s == mod.name } unless enabled_modules.include?(target)
    target.destroy unless target.blank?
  end

  safe_attributes 'name',
                  'description',
                  'homepage',
                  'is_public',
                  'identifier',
                  'custom_field_values',
                  'custom_fields',
                  'tracker_ids',
                  'issue_custom_field_ids',
                  'data_dal',
                  'data_al',
                  'titolo',
                  'search_key'

  safe_attributes 'enabled_module_names',
                  :if => lambda { |project, user| project.new_record? || user.allowed_to?(:select_project_modules, project) }

  # Returns an array of projects that are in this project's hierarchy
  #
  # Example: parents, children, siblings
  def hierarchy
    parents = project.self_and_ancestors || []
    descendants = project.descendants || []
    project_hierarchy = parents | descendants # Set union
  end

  # Returns an auto-generated project identifier based on the last identifier used
  def self.next_identifier
    p = Project.find(:first, :order => 'created_on DESC')
    p.nil? ? nil : p.identifier.to_s.succ
  end

  # Copies and saves the Project instance based on the +project+.
  # Duplicates the source project's:
  # * Wiki
  # * Versions
  # * Categories
  # * Issues
  # * Members
  # * Queries
  #
  # Accepts an +options+ argument to specify what to copy
  #
  # Examples:
  #   project.copy(1)                                    # => copies everything
  #   project.copy(1, :only => 'members')                # => copies members only
  #   project.copy(1, :only => ['members', 'versions'])  # => copies members and versions
  def copy(project, options={})
    project = project.is_a?(Project) ? project : Project.find(project)

    to_be_copied = %w(wiki versions issue_categories issues members queries boards)
    to_be_copied = to_be_copied & options[:only].to_a unless options[:only].nil?

    Project.transaction do
      if save
        reload
        to_be_copied.each do |name|
          send "copy_#{name}", project
        end
        Redmine::Hook.call_hook(:model_project_copy_before_save, :source_project => project, :destination_project => self)
        save
      end
    end
  end


  # Copies +project+ and returns the new instance.  This will not save
  # the copy
  def self.copy_from(project)
    begin
      project = project.is_a?(Project) ? project : Project.find(project)
      if project
        # clear unique attributes
        attributes = project.attributes.dup.except('id', 'name', 'identifier', 'status', 'parent_id', 'lft', 'rgt')
        copy = Project.new(attributes)
        copy.enabled_modules = project.enabled_modules
        copy.trackers = project.trackers
        copy.custom_values = project.custom_values.collect { |v| v.clone }
        copy.issue_custom_fields = project.issue_custom_fields
        return copy
      else
        return nil
      end
    rescue ActiveRecord::RecordNotFound
      return nil
    end
  end

  # Yields the given block for each project with its level in the tree
  def self.project_tree(projects, &block)
    ancestors = []
    #projects.sort_by(&:lft).each do |project|
    #Domthu20130125 Order project using nested set: changing the order
    #in the nested set would require changing the lft and rgt fields of a project
    #The lft, rgt and root_id columns used by the awesome_nested_set vendored with Redmine
    #=> prefered for last created appears first
    projects.sort_by(&:created_on).reverse.each do |project|
      while (ancestors.any? && !project.is_descendant_of?(ancestors.last))
        ancestors.pop
      end
      yield project, ancestors.size
      ancestors << project
    end
  end


  # --------------------------------NEWSLETTER-----------------------------------
  #

=begin
=======
>>>>>>> Move newsletter proc in public area from project model
  def newsletter(user = User.current)
    str = "<h1>" + self.name + "</h1>"
    str += "<h3>" + self.description + "</h3>"
    str += "<div>Numero di articoli presente in questa newsletter: " + self.issues.count.to_s + "</div>"
    #loop trovi codice fee
    #has_many :news_issues, :dependent => :destroy, :order => "#{Issue.table_name}.#{Section.table_name}.top_section_id DESC" , :include => [:status,{:section => :top_section} ]
    indice =""
    sommario =""
    last_top_section=0
    # for art in self.issues.sort_by &:section_id do
    for art in self.issues.all(:order => "#{Section.table_name}.top_section_id DESC") do
      if last_top_section != art.section.top_section_id
        indice += "<h3>" + art.section_id.to_s + " - "
        indice += art.section.to_s + " - "
        indice += (art.section.nil? ? "?" : art.section.top_section.to_s) + "</h3>"
        last_top_section = art.section.top_section_id
      end
      indice += smart_truncate(art.subject, 30) + "<br />"
      sommario += indice.nil? ? "?" : art.section.top_section.to_s
      sommario += smart_truncate(art.summary, 100) + "<br />"

    end
    str += "<h2> user corrente:" + user.name + "</h2>"
    str += "<br /><h1> INDICE </h1>"
    str += indice
    str += "<hr>"
    str += "<br /><h1> SOMMARIO </h1>"
    str += sommario


    return str
  end
<<<<<<< HEAD
=end


  def newsletter_smtp(u)
    s1="", s2="", s3="", s4="", s5="", last_tops=0, ancora ="", usr=nil
    usr = User.find_by_id u
    if !usr.blank?

      s1='<style type="text/css">
                /* Backgrounds */
            .email_background {
                width: 640px;
                background: url("http://es.pecchia.info/images/commons/email_bg.jpg") repeat-y;
            }
        </style>

        <!-- Contenitore -->
        <table cellpadding="0" cellspacing="0" border="0" width="99%" bgcolor="#0f6da1">
        <tr>
        <td align="center">
        <table cellpadding="0" cellspacing="0" border="0" width="640">
        <tr>
        <td>
        <!-- Pre Email -->
        <table cellpadding="0" cellspacing="0" border="0" width="640">
        <tr>
          <td valign="bottom" height="40" align="center">
            <font style="font-family: Tahoma, Arial, Helvetica, sans-serif; font-size:11px; color:#ffffff;">
              la newsletter di Fiscosport &nbsp;|&nbsp; L\'edizione
              <a target="_blank" href="http://fiscosport/edizione/' + self.id.to_s + ' style="color:#ffffff; text-decoration:underline;">
                num. '+ self.id.to_s + ' ' + self.description + '"</a> è online!</font>
          </td>
        </tr>
        <tr>
          <td>
            <table cellpadding="0" cellspacing="0" border="0" width="640" style="font-size:0;">
              <tr>
                <td>
                  <td valign="bottom"> <img  src="http://es.pecchia.info/images/commons/top_fade.jpg" width="640" height="20" border="0"/>
                </td>
              </tr>
            </table>
          </td>
        </tr>
        <tr>
          <td align="center" background="http://es.pecchia.info/images/commons/email_bg.jpg" class="email_background">
          </td>
        </tr>
        <tr>
        <td align="center" background="http://es.pecchia.info/images/commons/email_bg.jpg" class="email_background">
        <!-- inizio contenuto -->
        <!------------------------------------------------------------------------->'
      s2='<!-- Inizio sezione con logo e nomeutente -->
          <table width="560" border="0" cellpadding="0" cellspacing="0">
            <tr>
              <td width="242" height="110" align="left" valign="top">
                <!-- logo -->
               <a href="http://es.pecchia.info/editoriale/home" target="_blank" ><img src="http://es.pecchia.info/images/commons/fiscosport_news.jpg" alt="Fiscosport specialisti fiscali sportivi" border="0"></a>
           <td align="left" valign="top">
            <!-- tabella di 2 righe per il testo -->
            <table width="318" border="0" cellpadding="0" cellspacing="0">
              <tr>
                <td height="50" align="left" valign="center" style="border-bottom:1px solid #1C6693;">
                  <font style="font-family:Tahoma,Arial, Helvetica, sans-serif; font-size:14px; color:#333333; line-height: 18px; ">
                    Newsletter riservata a :<span style="font-size: 18px;">
                  ' + (usr.firstname? ? "&nbsp;" : usr.firstname) + "&nbsp;" + (usr.lastname.nil? ? "&nbsp;" : usr.lastname) + '</span>
                  </font></td>
              </tr>
              <tr>
                <td width="318" height="50" align="left" valign="center" style="border-bottom:1px solid #cccccc;">
                  <font style="font-family:Tahoma,Arial, Helvetica, sans-serif; font-size:13px; color:#333333; line-height:18px; font-weight: bold;">
                    ' + (usr.soc.nil? ? " " : usr.soc)+ ' </font>
                </td>
              </tr>
            </table>
            <!-- fine tabella di 2 righe per il testo -->
          </td>
        </tr>
      </table>
      <!-- fine sezione con logo e nomeutente -->
      <!-- inizio visibile solo se associato o affiliato-->'
      if usr.convention_id && (usr.convention_id > 0)
        s2 += '<table width="560" border="0" cellpadding="0" cellspacing="0">
            <tr>
              <td width="505" valign="bottom" bgcolor="#ffffff" height="50">
                <font style="font-family:Tahoma,Arial, Helvetica, sans-serif; font-size:12px; color:#333333; line-height:18px; font-weight: bold;">
                Covenzione da: ' + usr.convention.ragione_sociale + '</font>

              </td>
              <td width="55" valign="bottom" align="right">
                <img src="http://es.pecchia.info/images/banners/assos/ + usr.convention.logo  + " width="50" height="50" border="0" \>
              </td>
            </tr>
          </table>'
      else
        if usr.cross_organization
          s2 += '<table width="560" border="0" cellpadding="0" cellspacing="0">
              <tr>
                <td width="505" valign="bottom" bgcolor="#ffffff" height="50">
                  <font style="font-family:Tahoma,Arial, Helvetica, sans-serif; font-size:11px; color:#333333; line-height:18px; font-weight: bold;">
                    Affiliato a: ' + usr.cross_organization.to_s + '
                  </font>
                </td>
                <td width="55" valign="bottom" align="right">
                  <img src="http://es.pecchia.info/images/ico/fs.png" width="50" height="50" border="0" \>
                </td>
              </tr>
            </table>'
        end
      end
      s2 += '<!-- fine riga visibile solo se associato o è affiliato - sotto un\'ummagine di spazio -->
          <table width="560" border="0" cellpadding="0" cellspacing="0" style="font-size:0;">
            <tr>
              <td width="560" valign="bottom" bgcolor="#ffffff" height="6">
                <img src="http://es.pecchia.info/images/commons/email_spacer_colors.jpg" width="560" height="6" border="0" \>
              </td>
            </tr>
            <tr>
              <td width="560" valign="bottom" bgcolor="#ffffff" height="35">
                <img src="http://es.pecchia.info/images/commons/email_spacer.jpg" width="560" height="35" border="0" \>
              </td>
            </tr>
          </table>
            <!-------------------------------------------------------------------->
          <!-- inizio loop sezione indice --> '
      for nart in self.issues.all(:order => "#{Section.table_name}.top_section_id DESC", :include => [:section => :top_section]) do
        ancora = truncate(nart.subject, :length => 30).to_slug
        s3 += '<table width="560" border="0" cellpadding="0" cellspacing="0">'
        if last_tops != nart.section.top_section_id
          s3 += '<tr>
                <td height="14" bgcolor="#f5f5f5"></td>
                &nbsp; </tr>
              <tr>
                <td width="560" align="right" valign="top" bgcolor="#fefefe">
                  <table width="560" border="0" cellpadding="0" cellspacing="0">
                    <tr>
                      <td width="36" height="30" align="center" valign="top">
                        <img src="http://es.pecchia.info/images/ico/freg-y.png" border="0">
                      </td>
                      <td width="524" align="left" valign="center" bgcolor="ffffff" style="border-top:solid 1px #f1e9b8;">
                        <font style="font-family:Arial, Helvetica, sans-serif; font-size:15px; color:#333333; line-height:2em;">
                          <!-- sezione -->
                          <strong>
                            <span style="color: #0C4481;">
                            ' + (nart.section.nil? ? "? non trovata la sezione ?" : nart.section.top_section.to_s) + '</span>
                            :: <span style="color: #e95f03;"> ' + nart.section.to_s + '</span> </strong></font>
                      </td>
                    </tr>
                  </table>
                </td>
              </tr>'
        end
        s3 += '<!-- titolo --->
              <tr>
                <td width="560">
                  <table width="560" border="0" cellpadding="10" cellspacing="0">
                    <tr>
                      <td width="24" align="left" valign="center">
                        <a href="#'+ ancora +'" ><img src="http://es.pecchia.info/images/ico/fred24-y.png" border ="0"> </a>
                      </td>
                      <td width="536" align="left" valign="center">
                        <font style="font-family:Arial, Helvetica, sans-serif; font-size:14px;">
                          <strong>   <a href="#'+ ancora +'" style ="color:#333333; text-decoration: none;">' + nart.subject + '</strong></font><br/>
                      </td>
                    </tr>
                  </table>
                </td>
              </tr>
              <!-- fine titolo --->
            </table>'
        last_tops = nart.section.top_section_id
      end
      s3 += '<!-- fine loop sezione indice -->
            <!------------------------------------------------------------------------->
            <!--   -- spazio --  -->
            <table width="560" border="0" cellpadding="0" cellspacing="0" style="font-size:0;">
              <tr>
                <td height="33"></td>
              </tr>
              <tr>
                <td width="560" valign="bottom" bgcolor="#ffffff" height="35">
                  <img src="http://es.pecchia.info/images/commons/email_spacer.jpg" width="560" height="35" border="0" \>
                </td>
              </tr>
            </table>
            <!--inizio dicitura sommario  -->
            <table width="560" border="0" cellpadding="0" cellspacing="0">
              <tr>
                <td height="16"></td>
              </tr>
              <tr>
                <td width="100" align="right" valign="center" height="50">
                <img src="http://es.pecchia.info/images/commons/sommario_ico.jpg" alt="Sommario (icona)" \>
                </td>
                <td width="460" align="right" valign="center" height="50">
                <img src="http://es.pecchia.info/images/commons/sommario.jpg" alt="Sommario" \>
                </td>
              </tr>
              <tr>
                <td height="33"></td>
              </tr>
            </table>
            <!--fine  dicitura sommario  -->
            <!------------------------------------------------------------------------->
            <!-- inizio sezione loop articoli --> '
      for nart in self.issues.all(:order => "#{Section.table_name}.top_section_id DESC", :include => [:section => :top_section]) do
        ancora = truncate(nart.subject, :length => 30).to_slug
        s4 += '<table width="560" border="0" cellpadding="0" cellspacing="0">
              <tr>
                <td width="560" align="center" valign="top" bgcolor="#f4f4f4" style="border-top:1px solid #cccccc; border-bottom:1px solid #cccccc;">
                  <!-- inizio tabella contenuti -->
                  <table width="560" border="0" cellpadding="0" cellspacing="9">
                    <tr>
                      <!-- sotto: immagine sx -->
                      <td width="120" align="left" valign="top" rowspan="2">'
        if nart.immagine_url.nil?
          if FileTest.exist?("#{RAILS_ROOT}/public/images/commons/sections/#{nart.top_section.immagine}")
            s4 += '<a name="' + ancora + '"><img src="http://es.pecchia.info/images/commons/sections/' + nart.top_section.immagine + '" width ="120" \> </a>'
          else
            image_tag("/images/commons/sections/no-img.jpg", :width => 120, :id => ancora)
            s4 += '<a name="' + ancora + '"><img src="http://es.pecchia.info/images/commons/sections/no-img.jpg" width ="120" \> </a>'
          end
        else
          s4 += '<a name="' + ancora + '"><img src="' + nart.immagine_url + '" width ="120" alt="' + ancora + '" \> </a>'
        end
        s4 += '</td>
                    <!-- titolo  -->
                      <td width="440" align="left" valign="top">
                        <font style="font-family: Arial, Helvetica, sans-serif; font-size:16px; color:#003548; text-align: justify;">
                          <strong>' + nart.subject + '</strong> </font><br/>
                      </td>
                    </tr>
                    <tr>
                      <!--  riga autore  -->
                      <td width="440" align="right" valign="top">
                        <font style="font-family:Arial, Helvetica, sans-serif; font-size:12px; color:#333333; line-height:15px; text-decoration: underline; font-style: italic;">
                          <strong> <img src="http://es.pecchia.info/images/ico/pen24.png" border ="0">' + nart.author.to_s + '</strong>
                        </font>
                      </td>
                    </tr>
                    <tr>
                      <!-- riga riassunto -->
                      <td width="560" colspan="2">
                        <font style="font-family:Arial, Helvetica, sans-serif; font-size:15px; color:#000000; line-height:18px; ">
                          ' + nart.summary + '
                        </font><br/>
                      </td>
                    </tr>
                  </table>
                  <!--fine tabella contenuti -->
                  <!-- pulsante vedi -->
                  <table width="560" border="0" cellpadding="0" cellspacing="0">
                    <tr>
                      <td width="560" height="33" align="right" valign="top">
                     <a href="http://fiscosport.it/editoriale/'+ nart.section.top_section.top_menu.key + '/' + nart.section.top_section.key + '/' + nart.id.to_s + ' ' + truncate(nart.subject, :length => 125).to_slug + '" target="_blank" >
                              <img src="http://es.pecchia.info/images/commons/btn_news_y.gif" width="107" height="29" alt="vedi articolo" \> </a>
                      </td>
                    </tr>
                  </table>
                </td>
              </tr>
              <tr>
                <td width="560" height="13"></td>
              </tr>
            </table>
            <!-- fine sezione loop articoli -->'
      end
      s5 = '<!------------------------------------------------------------------------->
        <!-- IMPORTANTE fine   contenuto  email-->
        </table>
        </td>
        </tr>
        <tr>
          <td>
            <img src="http://es.pecchia.info/images/commons/bottom_fade.jpg" width="640" border="0" height="28"/>
          </td>
        </tr>
        <tr>
          <td valign="top" height="80" align="center">
            <font style="font-family: Tahoma, Arial, Helvetica, sans-serif; font-size:11px; color:#ffffff;">
              footer
            </font>
          </td>
        </table>
        </td>
        </tr>
        </table> '

      return s1+s2+s3+s4+s5
    else
      return '<h1 style="color:red;"> Utente id:[' + u.to_s + '] non trovato!</h1>'
    end
  end

  def set_creation_names()
    #edizione :  4/2012
    #4/2012 - QUINDICINALE del 23 febbraio 2012
    #e-4-2012
    #EDIZIONE_KEY = "e-"
    #QUESITO_ID = "e-quesiti"
    self.data_dal = Date.today
    self.data_al = Date.today + 15
    desired_year = self.data_al.year
    date_edizione = (((self.data_al.month) -1) * 2)
    if (self.data_al.day <= 15)
      abbr_meta = " --> prima "
      meta = "della prima meta di "
      date_edizione += 1
    else
      abbr_meta = " --> fine "
      meta = "della seconda meta di "
      date_edizione += 2
    end
    date_edizione -= 1  #MariaCristina il 20130517
    identificatore = date_edizione.to_s + "-" + desired_year.to_s
    flash_name = "QUINDICINALE"

    #Control uniqueness
    #.nil? can be used on any object and is true if the object is nil.
    #.empty? can be used on strings, arrays and hashes and returns true if:
    #Running .empty? on something that is nil will throw a NoMethodError.
    #That is where .blank? comes in. It is implemented by Rails and will operate on any object as well as work like .empty? on strings, arrays and hashes.
    yet_project = Project.find_by_identifier(FeeConst::EDIZIONE_KEY.to_s + identificatore)
    if yet_project #|| !@yet_project.nil?
                   #provi di creare un BIS
                   #edizione :  2bis/2012
                   #2bis/2012 - FISCOSPORT FLASH DEL 1/02/2012
                   #e-2bis-2012
      identificatore = date_edizione.to_s + "bis-" + desired_year.to_s

      yet_project = Project.find_by_identifier(FeeConst::EDIZIONE_KEY.to_s + identificatore)
      if yet_project #|| !@yet_project.nil?
                     #provo di cercare il numero di edizioni create questo anno
        num_edizioni = Project.count(:conditions => ['identifier LIKE ? AND extract(year from data_al) = ?', "#{FeeConst::EDIZIONE_KEY}%", desired_year])
        #Model.where("strftime('%Y', date_column)     = ?", desired_year)
        identificatore = (num_edizioni + 1).to_s + "-" + desired_year.to_s

        yet_project = Project.find_by_identifier(FeeConst::EDIZIONE_KEY.to_s + identificatore)
        if yet_project #|| !@yet_project.nil?
                       #prendo l'ultima edizione creato questo anno
          yet_project = Project.first(:conditions => ['identifier LIKE ?', "#{FeeConst::EDIZIONE_KEY}%"], :order => 'created_on DESC')
          if yet_project && !yet_project.nil?
            self.data_al = yet_project.data_al + 15
            desired_year = self.data_al.year
            date_edizione = (((self.data_al.month) -1) * 2)
            if (self.data_al.day <= 15)
              abbr_meta = " --> prima "
              meta = "della prima meta di "
              date_edizione += 1
            else
              abbr_meta = " --> fine "
              meta = "della seconda meta di "
              date_edizione += 2
            end
            identificatore = date_edizione.to_s + "-" + desired_year.to_s

          else
            flash[:notice] = l(:notice_ensure_identifier)
          end
        end
      else
        flash_name = "FISCOSPORT FLASH"
      end
    end


    self.identifier = FeeConst::EDIZIONE_KEY + identificatore
    identificatore = identificatore.sub("-", "/")

    #self.name = "edizione:  " + identificatore
    #self.name += abbr_meta
    ##self.name += self.data_al.strftime("%B") + "\r\n"
    #self.name += l('date.abbr_month_names')[self.data_al.month] + "\r\n"
    #3/2013 - QUINDICINALE dell'8 febbraio 2013
    self.name = identificatore + " QUINDICINALE del " + self.data_al.strftime("%e ")
    self.name += l('date.month_names')[self.data_al.month].downcase
    self.name += self.data_al.strftime(" %Y")

    self.description = identificatore + " - " + flash_name + " del "
    self.description += self.data_al.strftime("%d ")
    self.description += l('date.month_names')[self.data_al.month] + " "
    self.description += self.data_al.strftime("%Y \r\n\r\n")

    self.search_key = "edizione " + Date.today.year.to_s

    self.description = "h3. " + self.description
    self.description += "h2. Newsletter bisettimanale "
    self.description += meta
    #self.description += self.data_al.strftime("%B") + "\r\n"
    self.description += l('date.month_names')[self.data_al.month] + "\r\n"
    self.description += "COMMENTO della redazione\r\n"
    self.description += "<pre>\r\n"
    self.description += "\r\n"
    self.description += "</pre>\r\n"
    self.description += "*Redazione Fiscosport*"
  end

  #Move newsletter proc in public area from project model

  # --------------------------------PRIVATE AREA-----------------------------------
  #
  private

  # Copies wiki from +project+
  def copy_wiki(project)
    # Check that the source project has a wiki first
    unless project.wiki.nil?
      self.wiki ||= Wiki.new
      wiki.attributes = project.wiki.attributes.dup.except("id", "project_id")
      wiki_pages_map = {}
      project.wiki.pages.each do |page|
        # Skip pages without content
        next if page.content.nil?
        new_wiki_content = WikiContent.new(page.content.attributes.dup.except("id", "page_id", "updated_on"))
        new_wiki_page = WikiPage.new(page.attributes.dup.except("id", "wiki_id", "created_on", "parent_id"))
        new_wiki_page.content = new_wiki_content
        wiki.pages << new_wiki_page
        wiki_pages_map[page.id] = new_wiki_page
      end
      wiki.save
      # Reproduce page hierarchy
      project.wiki.pages.each do |page|
        if page.parent_id && wiki_pages_map[page.id]
          wiki_pages_map[page.id].parent = wiki_pages_map[page.parent_id]
          wiki_pages_map[page.id].save
        end
      end
    end
  end

  # Copies versions from +project+
  def copy_versions(project)
    project.versions.each do |version|
      new_version = Version.new
      new_version.attributes = version.attributes.dup.except("id", "project_id", "created_on", "updated_on")
      self.versions << new_version
    end
  end

  # Copies issue categories from +project+
  def copy_issue_categories(project)
    project.issue_categories.each do |issue_category|
      new_issue_category = IssueCategory.new
      new_issue_category.attributes = issue_category.attributes.dup.except("id", "project_id")
      self.issue_categories << new_issue_category
    end
  end

  # Copies issues from +project+
  # Note: issues assigned to a closed version won't be copied due to validation rules
  def copy_issues(project)
    # Stores the source issue id as a key and the copied issues as the
    # value.  Used to map the two togeather for issue relations.
    issues_map = {}

    # Get issues sorted by root_id, lft so that parent issues
    # get copied before their children
    project.issues.find(:all, :order => 'root_id, lft').each do |issue|
      new_issue = Issue.new
      new_issue.copy_from(issue)
      new_issue.project = self
      # Reassign fixed_versions by name, since names are unique per
      # project and the versions for self are not yet saved
      if issue.fixed_version
        new_issue.fixed_version = self.versions.select { |v| v.name == issue.fixed_version.name }.first
      end
      # Reassign the category by name, since names are unique per
      # project and the categories for self are not yet saved
      if issue.category
        new_issue.category = self.issue_categories.select { |c| c.name == issue.category.name }.first
      end
      # Parent issue
      if issue.parent_id
        if copied_parent = issues_map[issue.parent_id]
          new_issue.parent_issue_id = copied_parent.id
        end
      end

      self.issues << new_issue
      if new_issue.new_record?
        logger.info "Project#copy_issues: issue ##{issue.id} could not be copied: #{new_issue.errors.full_messages}" if logger && logger.info
      else
        issues_map[issue.id] = new_issue unless new_issue.new_record?
      end
    end

    # Relations after in case issues related each other
    project.issues.each do |issue|
      new_issue = issues_map[issue.id]
      unless new_issue
        # Issue was not copied
        next
      end

      # Relations
      issue.relations_from.each do |source_relation|
        new_issue_relation = IssueRelation.new
        new_issue_relation.attributes = source_relation.attributes.dup.except("id", "issue_from_id", "issue_to_id")
        new_issue_relation.issue_to = issues_map[source_relation.issue_to_id]
        if new_issue_relation.issue_to.nil? && Setting.cross_project_issue_relations?
          new_issue_relation.issue_to = source_relation.issue_to
        end
        new_issue.relations_from << new_issue_relation
      end

      issue.relations_to.each do |source_relation|
        new_issue_relation = IssueRelation.new
        new_issue_relation.attributes = source_relation.attributes.dup.except("id", "issue_from_id", "issue_to_id")
        new_issue_relation.issue_from = issues_map[source_relation.issue_from_id]
        if new_issue_relation.issue_from.nil? && Setting.cross_project_issue_relations?
          new_issue_relation.issue_from = source_relation.issue_from
        end
        new_issue.relations_to << new_issue_relation
      end
    end
  end

  # Copies members from +project+
  def copy_members(project)
    # Copy users first, then groups to handle members with inherited and given roles
    members_to_copy = []
    members_to_copy += project.memberships.select { |m| m.principal.is_a?(User) }
    members_to_copy += project.memberships.select { |m| !m.principal.is_a?(User) }

    members_to_copy.each do |member|
      new_member = Member.new
      new_member.attributes = member.attributes.dup.except("id", "project_id", "created_on")
      # only copy non inherited roles
      # inherited roles will be added when copying the group membership
      role_ids = member.member_roles.reject(&:inherited?).collect(&:role_id)
      next if role_ids.empty?
      new_member.role_ids = role_ids
      new_member.project = self
      self.members << new_member
    end
  end

  # Copies queries from +project+
  def copy_queries(project)
    project.queries.each do |query|
      new_query = Query.new
      new_query.attributes = query.attributes.dup.except("id", "project_id", "sort_criteria")
      new_query.sort_criteria = query.sort_criteria if query.sort_criteria
      new_query.project = self
      new_query.user_id = query.user_id
      self.queries << new_query
    end
  end

  # Copies boards from +project+
  def copy_boards(project)
    project.boards.each do |board|
      new_board = Board.new
      new_board.attributes = board.attributes.dup.except("id", "project_id", "topics_count", "messages_count", "last_message_id")
      new_board.project = self
      self.boards << new_board
    end
  end

  def allowed_permissions
    @allowed_permissions ||= begin
      module_names = enabled_modules.all(:select => :name).collect { |m| m.name }
      Redmine::AccessControl.modules_permissions(module_names).collect { |p| p.name }
    end
  end

  def allowed_actions
    @actions_allowed ||= allowed_permissions.inject([]) { |actions, permission| actions += Redmine::AccessControl.allowed_actions(permission) }.flatten
  end

  # Returns all the active Systemwide and project specific activities
  def active_activities
    overridden_activity_ids = self.time_entry_activities.collect(&:parent_id)

    if overridden_activity_ids.empty?
      return TimeEntryActivity.shared.active
    else
      return system_activities_and_project_overrides
    end
  end

  # Returns all the Systemwide and project specific activities
  # (inactive and active)
  def all_activities
    overridden_activity_ids = self.time_entry_activities.collect(&:parent_id)

    if overridden_activity_ids.empty?
      return TimeEntryActivity.shared
    else
      return system_activities_and_project_overrides(true)
    end
  end

  # Returns the systemwide active activities merged with the project specific overrides
  def system_activities_and_project_overrides(include_inactive=false)
    if include_inactive
      return TimeEntryActivity.shared.
          find(:all,
               :conditions => ["id NOT IN (?)", self.time_entry_activities.collect(&:parent_id)]) +
          self.time_entry_activities
    else
      return TimeEntryActivity.shared.active.
          find(:all,
               :conditions => ["id NOT IN (?)", self.time_entry_activities.collect(&:parent_id)]) +
          self.time_entry_activities.active
    end
  end

  # Archives subprojects recursively
  def archive!
    children.each do |subproject|
      subproject.send :archive!
    end
    update_attribute :status, STATUS_ARCHIVED
  end

end

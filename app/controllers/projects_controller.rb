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

class ProjectsController < ApplicationController
  menu_item :overview
  menu_item :roadmap, :only => :roadmap
  menu_item :settings, :only => :settings

  before_filter :find_project, :except => [ :index, :list, :new, :create, :copy ]
  before_filter :authorize, :except => [ :index, :list, :new, :create, :copy, :archive, :unarchive, :destroy]
  before_filter :authorize_global, :only => [:new, :create]
  before_filter :require_admin, :only => [ :copy, :archive, :unarchive, :destroy ]
  accept_rss_auth :index
  accept_api_auth :index, :show, :create, :update, :destroy

  after_filter :only => [:create, :edit, :update, :archive, :unarchive, :destroy] do |controller|
    if controller.request.post?
      controller.send :expire_action, :controller => 'welcome', :action => 'robots.txt'
    end
  end

  helper :sort
  include SortHelper
  helper :custom_fields
  include CustomFieldsHelper
  helper :issues
  helper :queries
  include QueriesHelper
  helper :repositories
  include RepositoriesHelper
  include ProjectsHelper
  include FeesHelper  #Domthu  FeeConst

  # Lists visible projects
  def index
    respond_to do |format|
      format.html {
        #@projects = Project.visible.find(:all, :order => 'lft')
        #Domthu20130125 Order project using nested set: changing the order
        #in the nested set would require changing the lft and rgt fields of a project
        #The lft, rgt and root_id columns used by the awesome_nested_set vendored with Redmine
        #=> prefered for last updated appears first
        @projects = Project.visible.find(:all, :order => 'data_al DESC, updated_on DESC, lft')
      }
      format.api  {
        @offset, @limit = api_offset_and_limit
        @project_count = Project.visible.count
        @projects = Project.visible.all(:offset => @offset, :limit => @limit, :order => 'lft')
      }
      format.atom {
        projects = Project.visible.find(:all, :order => 'created_on DESC',
                                              :limit => Setting.feeds_limit.to_i)
        render_feed(projects, :title => "#{Setting.app_title}: #{l(:label_project_latest)}")
      }
    end
  end

  def new
    @issue_custom_fields = IssueCustomField.find(:all, :order => "#{CustomField.table_name}.position")
    @trackers = Tracker.all
    @project = Project.new

    #domthu20130126
    @project.set_creation_names()
    @managers = User.all(:conditions => {:role_id => FeeConst::ROLE_MANAGER, :admin => false })
    @authors = User.all(:conditions => {:role_id => FeeConst::ROLE_AUTHOR, :admin => false})
    @lastproject = Project.all(:limit => 10, :order => 'created_on DESC')

    @project.safe_attributes = params[:project]
  end

  verify :method => :post, :only => :create, :render => {:nothing => true, :status => :method_not_allowed }
  def create
    @issue_custom_fields = IssueCustomField.find(:all, :order => "#{CustomField.table_name}.position")
    @trackers = Tracker.all
    @project = Project.new
    @project.safe_attributes = params[:project]

    if validate_parent_id && @project.save
      @project.set_allowed_parent!(params[:project]['parent_id']) if params[:project].has_key?('parent_id')
      # Add current user as a project member if he is not admin
      unless User.current.admin?
        r = Role.givable.find_by_id(Setting.new_project_user_role_id.to_i) || Role.givable.first
        m = Member.new(:user => User.current, :roles => [r])
        @project.members << m
      end

      @project.members_fs_add_author_manager(nil, nil)
#      #begin
#      #Domthu Add all collaboratori as a project members
#      #user.role_id = Redattore
#      @managers = User.all(:conditions => {:role_id => FeeConst::ROLE_MANAGER, :admin => false })
#      @authors = User.all(:conditions => {:role_id => FeeConst::ROLE_AUTHOR, :admin => false})
#      #puts "***********MANAGER*****************************"
#      #puts @managers
#      for usr in @managers
#        member = Member.new
#        member.user = usr
#        #3 	Manager
#        #member.roles = [Role.find_by_name('Manager')]
#        member.roles = [Role.find_by_id(FeeConst::ROLE_MANAGER)]
#        #ActiveRecord::RecordInvalid (Validation failed: Ruolo non è valido):
#        #member.project = @project
#        #member.save
#        @project.members << member
#      end
#      #puts "***********AUTHORS*****************************"
#      #puts @authors
#      for usr in @authors
#        member = Member.new
#        member.user = usr
#        #4 	Redattore
#        #member.roles = [Role.find_by_name('Redattore')]
#        member.roles = [Role.find_by_id(FeeConst::ROLE_AUTHOR)]
#        #member.project = @project
#        #member.save
#        @project.members << member
#      end
#      #puts "***********************************************"
#      #rescue

      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_create)
          redirect_to(params[:continue] ?
            {:controller => 'projects', :action => 'new', :project => {:parent_id => @project.parent_id}.reject {|k,v| v.nil?}} :
            {:controller => 'projects', :action => 'settings', :id => @project}
          )
        }
        format.api  { render :action => 'show', :status => :created, :location => url_for(:controller => 'projects', :action => 'show', :id => @project.id) }
      end
    else
      respond_to do |format|
        format.html { render :action => 'new' }
        format.api  { render_validation_errors(@project) }
      end
    end

  end

  def copy
    @issue_custom_fields = IssueCustomField.find(:all, :order => "#{CustomField.table_name}.position")
    @trackers = Tracker.all
    @root_projects = Project.find(:all,
                                  :conditions => "parent_id IS NULL AND status = #{Project::STATUS_ACTIVE}",
                                  :order => 'name')
    @source_project = Project.find(params[:id])
    if request.get?
      @project = Project.copy_from(@source_project)
      if @project
        @project.identifier = Project.next_identifier if Setting.sequential_project_identifiers?
      else
        redirect_to :controller => 'admin', :action => 'projects'
      end
    else
      Mailer.with_deliveries(params[:notifications] == '1') do
        @project = Project.new
        @project.safe_attributes = params[:project]
        if validate_parent_id && @project.copy(@source_project, :only => params[:only])
          @project.set_allowed_parent!(params[:project]['parent_id']) if params[:project].has_key?('parent_id')
          flash[:notice] = l(:notice_successful_create)
          redirect_to :controller => 'projects', :action => 'settings', :id => @project
        elsif !@project.new_record?
          # Project was created
          # But some objects were not copied due to validation failures
          # (eg. issues from disabled trackers)
          # TODO: inform about that
          redirect_to :controller => 'projects', :action => 'settings', :id => @project
        end
      end
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to :controller => 'admin', :action => 'projects'
  end

  # Show @project
  def show
    if params[:jump]
      # try to redirect to the requested menu item
      #domthu avoid the need to redirect here, prefere refactor the search engine and URL redirect
      #if User.current.allowed_to?(:access_back_end, nil, :global => true)
      redirect_to_project_menu_item(@project, params[:jump]) && return
      #else
      #  redirect_to edizione_path(@project, params[:jump]) && return
      #end
    end
    #sandro --problema di accesso per author nella visualizzazione projects (edizioni) messo solo parametro  n2 context = @project
    #if not User.current.allowed_to?(:access_back_end, nil, :global => true)
    #  redirect_to(url_for(:controller => 'editorial', :action => 'edizione', :id => params[:id]))
    #  return
    #end
    unless User.current.allowed_to?(:access_back_end, @project, :global => true)
      redirect_to(url_for(:controller => 'editorial', :action => 'edizione', :id => params[:id]))
      return
    end



    @users_by_role = @project.users_by_role
    @subprojects = @project.children.visible.all
    @news = @project.news.find(:all, :limit => 5, :include => [ :author, :project ], :order => "#{News.table_name}.created_on DESC")
    @trackers = @project.rolled_up_trackers

    cond = @project.project_condition(Setting.display_subprojects_issues?)

    @open_issues_by_tracker = Issue.visible.count(:group => :tracker,
                                            :include => [:project, :status, :tracker],
                                            :conditions => ["(#{cond}) AND #{IssueStatus.table_name}.is_closed=?", false])
    @total_issues_by_tracker = Issue.visible.count(:group => :tracker,
                                            :include => [:project, :status, :tracker],
                                            :conditions => cond)

    @conv_futuri = Issue.solo_convegni.all(:include => [:project, :status, :reservations, {:section => :top_section}], :conditions => ["(#{cond})"])
    #@newsport = Issue.solo_newsport.find(:include => [:project, :status, :tracker], :conditions => ["(#{cond})"])

    @quesiti = Issue.solo_quesiti.all(:include => [:project, :status, :quesito_news, {:author => :user_profile}, {:section => :top_section}], :conditions => ["(#{cond})"])

    if User.current.allowed_to?(:view_time_entries, @project)
      @total_hours = TimeEntry.visible.sum(:hours, :include => :project, :conditions => cond).to_f
    end

    @key = User.current.rss_key

    respond_to do |format|
      format.html
      format.api
    end
  end

  def settings
    @issue_custom_fields = IssueCustomField.find(:all, :order => "#{CustomField.table_name}.position")
    @issue_category ||= IssueCategory.new
    @member ||= @project.members.new
    @trackers = Tracker.all
    @repository ||= @project.repository
    @wiki ||= @project.wiki
  end

  def edit
  end


  # TODO: convert to PUT only
  verify :method => [:post, :put], :only => :update, :render => {:nothing => true, :status => :method_not_allowed }
  def update
    @project.safe_attributes = params[:project]

    if validate_parent_id && @project.save
      @project.set_allowed_parent!(params[:project]['parent_id']) if params[:project].has_key?('parent_id')
      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_update)
          redirect_to :action => 'settings', :id => @project
        }
        format.api  { head :ok }
      end
    else
      respond_to do |format|
        format.html {
          settings
          render :action => 'settings'
        }
        format.api  { render_validation_errors(@project) }
      end
    end
  end

  verify :method => :post, :only => :modules, :render => {:nothing => true, :status => :method_not_allowed }
  def modules
    @project.enabled_module_names = params[:enabled_module_names]
    flash[:notice] = l(:notice_successful_update)
    redirect_to :action => 'settings', :id => @project, :tab => 'modules'
  end

  def archive
    if request.post?
      unless @project.archive
        flash[:error] = l(:error_can_not_archive_project)
      end
    end
    redirect_to(url_for(:controller => 'admin', :action => 'projects', :status => params[:status]))
  end

  def unarchive
    @project.unarchive if request.post? && !@project.active?
    redirect_to(url_for(:controller => 'admin', :action => 'projects', :status => params[:status]))
  end

  # Delete @project
  def destroy
    @project_to_destroy = @project
    if request.get?
      # display confirmation view
    else
      if api_request? || params[:confirm]

        if @project_to_destroy.id == FeeConst::QUESITO_ID
          flash[:error] = l(:error_can_not_delete_system, :name => FeeConst::QUESITO_KEY)
        else
          @project_to_destroy.destroy
        end

        respond_to do |format|
          format.html { redirect_to :controller => 'admin', :action => 'projects' }
          format.api  { head :ok }
        end
      end
    end
    # hide project in layout
    @project = nil
  end

private
  def find_optional_project
    return true unless params[:id]
    @project = Project.find(params[:id])
    authorize
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # Validates parent_id param according to user's permissions
  # TODO: move it to Project model in a validation that depends on User.current
  def validate_parent_id
    return true if User.current.admin?
    parent_id = params[:project] && params[:project][:parent_id]
    if parent_id || @project.new_record?
      parent = parent_id.blank? ? nil : Project.find_by_id(parent_id.to_i)
      unless @project.allowed_parents.include?(parent)
        @project.errors.add :parent_id, :invalid
        return false
      end
    end
    true
  end
end

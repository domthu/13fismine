# Redmine - project management software
# Copyright (C) 2006-2011  Jean-Philippe Lang
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

class NewsController < ApplicationController
  default_search_scope :news
  model_object News
  include FeesHelper
  #Kappao include ActionView::Helpers::UrlHelper #use link_to in controller

  before_filter :find_model_object, :except => [:new, :create, :index]
  before_filter :find_project_from_association, :except => [:new, :create, :index, :assign]
  before_filter :find_project, :only => [:new, :create, :assign]
  before_filter :find_news, :only => [:assign]
  before_filter :authorize, :except => [:index, :assign]
  before_filter :find_optional_project, :only => :index
  accept_rss_auth :index
  accept_api_auth :index

  helper :watchers

  def index
    case params[:format]
    when 'xml', 'json'
      @offset, @limit = api_offset_and_limit
    else
      @limit =  10
    end

    scope = @project ? @project.news.visible : News.visible

    @news_count = scope.count
    @news_pages = Paginator.new self, @news_count, @limit, params['page']
    @offset ||= @news_pages.current.offset
    @newss = scope.all(:include => [:author, :project],
                                       :order => "#{News.table_name}.created_on DESC",
                                       :offset => @offset,
                                       :limit => @limit)

    respond_to do |format|
      format.html {
        @news = News.new # for adding news inline
        render :layout => false if request.xhr?
      }
      format.api
      format.atom { render_feed(@newss, :title => (@project ? @project.name : Setting.app_title) + ": #{l(:label_news_plural)}") }
    end
  end

  def show
    if not User.current.allowed_to?(:access_back_end, nil, :global => true)
      redirect_to(url_for(:controller => 'editorial', :action => 'quesito_full', :id => params[:id]))
      return
    end

    @comments = @news.comments
    @comments.reverse! if User.current.wants_comments_in_reverse_order?
  end

  def new
    @news = News.new(:project => @project, :author => User.current)
  end

  def create
    @news = News.new(:project => @project, :author => User.current)
    @news.safe_attributes = params[:news]
    if request.post?
      if @news.save
        flash[:notice] = l(:notice_successful_create)
        redirect_to :controller => 'news', :action => 'index', :project_id => @project
      else
        render :action => 'new'
      end
    end
  end

  def edit
  end

  def update
    @news.safe_attributes = params[:news]
    if request.put? and @news.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to :action => 'show', :id => @news
    else
      render :action => 'edit'
    end
  end

  def assign
    flash[:errors] = l(:error_none_assigned)
    return
    #find_project reccupera il progetto associato
    #if params[:watcher_user_ids].is_a?(Hash)
    if !@news.nil? && @news.project.identifier == FeeConst::QUESITO_KEY
      #if params[:watcher_user_ids] && params[:watcher_user_ids].is_a?(Hash)
      if params[:watcher_user_ids] #&& params[:watcher_user_ids].is_a?(Hash)
        #if User.current.allowed_to?(:add_issue_watchers, @news.project)
        if User.current.admin? ||  User.current.ismanager?
          #watcher_user_ids = params[:news]['watcher_user_ids']
          #watcher_user_ids = params[:watcher_user_ids]
          @watcher_user_ids = params[:watcher_user_ids]
          if @watcher_user_ids.count > 0
            @watcher_user_ids.each_with_index { |collaboratore_id, i |
                #crea nuova issue
                new_issue = Issue.new
                collaboratore = User.find_by_id(collaboratore_id)
                #new_issue.copy_from(issue)
                new_issue.project_id = @news.project.id
                new_issue.news_id = @news.id
                if (Section.all_quesiti.count > 0)
                  #default FeeConst::TMENU_QUESITO
                  new_issue.section_id = Section.all_quesiti.first.id
                end
                new_issue.assigned_to_id = collaboratore.id
                new_issue.author = collaboratore
                new_issue.watcher_user_ids = @watcher_user_ids
                new_issue.tracker = @news.project.trackers.first
                new_issue.start_date = Date.today
                new_issue.due_date = 15.day.from_now.to_date
                new_issue.subject = "Risposta al " + @news.title
                new_issue.summary = "Testo della domanda: " + @news.summary
                #new_issue.save!  #--> save_without_transactions
                new_issue.save
                if flash[:notice].nil?
                  flash[:notice] = "<b>" + (i + 1).to_s + "</b>: " + l(:notice_successful_assigned) + @watcher_user_ids.count.to_s
                else
                  flash[:notice] += "</br><b>" + (i + 1).to_s + "</b>: " + l(:notice_successful_assigned) + @watcher_user_ids.count.to_s
                end
                #Aggiorno lo stato della news
                @news.status_id = FeeConst::QUESITO_STATUS_ISSUES_REPLY
                @news.save
            }
          else
            flash[:errors] = l(:news_assign_not_allowed)
          end
        else
          flash[:errors] = l(:news_assign_not_allowed)
        end
      else
        flash[:errors] = l(:error_none_assigned)
      end
      redirect_to :action => 'show', :id => @news.id
    else
      flash[:errors] = l(:none_found_news)
      redirect_to :action => 'index'
    end
  end

  def destroy
    #control if exists some issues
    if @news.issues.empty? || @news.issues.count <= 0
      @news.destroy
      redirect_to :action => 'index', :project_id => @project
    else
      flash[:notice] = l(:cannot_delete_related_news, :num =>  @news.issues.count)
      @news.issues.each_with_index { |issue, i |
        #Kappao include ActionView::Helpers::UrlHelper #use link_to in controller
        #flash[:notice] += "</br><b>" + (i + 1).to_s + "</b>: " + link_to_issue(issue)
        flash[:notice] += "</br><b>" + (i + 1).to_s + "</b>: " + issue.to_s
      }
      redirect_to :action => 'show', :id => @news
    end
  end

private
  def find_news
    @news = News.find(:first, :include => [:project], :conditions => ["id =  ?", params[:news]['news_id']])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_optional_project
    return true unless params[:project_id]
    @project = Project.find(params[:project_id])
    authorize
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end

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

class NewsController < ApplicationController
  default_search_scope :news
  model_object News
  include FeesHelper #Domthu  FeeConst
                     #Kappao include ActionView::Helpers::UrlHelper #use link_to in controller

  before_filter :find_model_object, :except => [:new, :create, :index, :assegna_js]
  before_filter :find_project_from_association, :except => [:new, :create, :index, :assign, :assegna_js]
  before_filter :find_project, :only => [:new, :create, :assign]
  before_filter :find_news, :only => [:assign, :assegna_js]
  before_filter :authorize, :except => [:index, :assign, :assegna_js]
  before_filter :find_optional_project, :only => :index
  accept_rss_auth :index
  accept_api_auth :index

  helper :watchers

  def index
    case params[:format]
      when 'xml', 'json'
        @offset, @limit = api_offset_and_limit
      else
        @limit = 10
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

#"_method"=>"put", "controller"=>"news", "authenticity_token"=>"MArud2DChLjHk6dsQsNS4+WRVxkV499uGZZwDQmfMZM=", "id"=>"3614", "action"=>"update", "news"=>{"reply"=>"<p>\r\n\ttest</p>\r\n"}, "commit"=>"Fai una risposta veloce"
  def update

    @news.safe_attributes = params[:news]
    if request.put? and @news.save
      send_notice(l(:notice_successful_update))

      #quesito set
      if @news.project.identifier == FeeConst::QUESITO_KEY && @news.is_quesito? && @news.reply != '' && (User.current.admin? || User.current.ismanager? || User.current == @issue.author)
       # questo unless che segue é solo per salvare le modifiche del quesito non della risposta
        unless params[:change_only_quesito].present?
          send_notice("Procedura risposta veloce al quesito mediante news")
          #controllare che la news possa andare in risposta veloce
          # solo se non ci sono altri issue con campo descrizione già attive
          @news.issues.each { |issue|
            if issue.project.identifier != FeeConst::QUESITO_KEY
              send_warning( l(:alert_another_responses, :link => issue.to_s, :author => issue.author))
            else
              #elimino anche se non è vuoto il campo descrizione
              #se non è vuoto vuole dire che un collaboratore assegnato
              #ha iniziato a scrivere una riposta
              if issue.description? && !issue.description.blank?
                send_notice( l(:deleted_issue_pre) + (i + 1).to_s + "</b> " + l(:deleted_issue, :name => del_issue.to_s, :author => del_issue.author))
              else
                send_notice("<b>" + (i + 1).to_s + "</b>: " + l(:deleted_issue, :name => del_issue.to_s, :author => del_issue.author))
              end
              issue.destroy
            end
          }

          @news.status_id = FeeConst::QUESITO_STATUS_FAST_REPLY
          @news.save
          send_notice("Quesito chiuso. Stato impostato a Risposta veloce")
        end
      end
      redirect_to :action => 'show', :id => @news
    else
      render :action => 'edit'
    end
  end

  def update_txt
    @news.safe_attributes = params[:news]
    if request.put? and @news.save
      send_notice(l(:notice_successful_update))
      redirect_to :action => 'show', :id => @news
    else
      render :action => 'edit'
      send_notice(l(:label_fail_update))
    end
  end

  def assign
    #puts "******************ASSIGN************************+"
    return redirect_to :action => 'index'
  end

  #via js
  def assegna_js
    #puts "******************ASSEGNA************************+"
    #find_project reccupera il progetto associato
    #if params[:watcher_user_ids].is_a?(Hash)
    if !@news.nil? && @news.project.identifier == FeeConst::QUESITO_KEY
      #if params[:watcher_user_ids] && params[:watcher_user_ids].is_a?(Hash)
      if params[:watcher_user_ids] #&& params[:watcher_user_ids].is_a?(Hash)
                                   #if User.current.allowed_to?(:add_issue_watchers, @news.project)
        if User.current.admin? || User.current.ismanager?
          #watcher_user_ids = params[:news]['watcher_user_ids']
          #watcher_user_ids = params[:watcher_user_ids]
          @watcher_user_ids = params[:watcher_user_ids]
          if @watcher_user_ids.count > 0
            @watcher_user_ids.each_with_index { |collaboratore_id, i|
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
              send_notice("<b>" + (i + 1).to_s + "</b>: " + l(:notice_successful_assigned, :author => collaboratore.name) + @watcher_user_ids.count.to_s)
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
      #return redirect_to :action => 'show', :id => @news.id
    else
      flash[:errors] = l(:none_found_news)
      #return redirect_to :action => 'index'
    end
    respond_to do |format|
      format.js {
        render(:update) { |page|
          page.replace_html "div_issues_responses", :partial => 'show_quesito_issues'
          page.replace_html "div_fast_reply", :partial => 'form_reply_fast.html'
          page.visual_effect(:highlight, "assegnati")
        }
      }
    end
  end

  def destroy
    #control if exists some issues
    if @news.issues.empty? || @news.issues.count <= 0
      @news.destroy
      redirect_to :action => 'index', :project_id => @project
    else
      send_notice(l(:cannot_delete_related_news, :num => @news.issues.count))
      @news.issues.each_with_index { |issue, i|
        send_notice("<b>" + (i + 1).to_s + "</b>: " + issue.to_s)
      }
      redirect_to :action => 'show', :id => @news
    end
  end

  private
  def find_news
    @news_id = params[:news]['news_id']
    puts "*************news_id: " + @news_id.to_s
    @news = News.find(:first, :include => [:project], :conditions => ['id =  ?', @news_id.to_s])
      #@news = News.find(@news_id, :include => [:project])
      #@news = News.find(:first, :include => [:project], :conditions => ['id =  ?', params[:news]['news_id']])
  rescue ActiveRecord::RecordNotFound
    puts "*******************************+"
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

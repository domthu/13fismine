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
=begin
  def index
    page
    render :action => 'page'
  end

  # Show user's page
  def page
    @user = User.current
    @blocks = @user.pref[:my_page_layout] || DEFAULT_LAYOUT
  end
=end

class AdminController < ApplicationController
  layout 'admin'
  before_filter :require_admin
  helper :sort
  include SortHelper
  helper :calendars
  include CalendarsHelper
  helper :issues
  helper :queries
  include QueriesHelper


  def index
    @no_configuration_data = Redmine::DefaultData::Loader::no_data?
    @user = User.current
    # da qui copiata per il calendario
    if params[:year] and params[:year].to_i > 1900
      @year = params[:year].to_i
      if params[:month] and params[:month].to_i > 0 and params[:month].to_i < 13
        @month = params[:month].to_i
      end
    end
    @year ||= Date.today.year
    @month ||= Date.today.month

    @calendar = Redmine::Helpers::Calendar.new(Date.civil(@year, @month, 1), current_language, :month)
    retrieve_query_my
    @query.group_by = nil
    if @query.valid?
      events = []
      events += @query.issues(:include => [:tracker, :assigned_to, :priority],
                              :conditions => ["((start_date BETWEEN ? AND ?) OR (due_date BETWEEN ? AND ?))", @calendar.startdt, @calendar.enddt, @calendar.startdt, @calendar.enddt]
                              )
      events += @query.versions(:conditions => ["effective_date BETWEEN ? AND ?", @calendar.startdt, @calendar.enddt])

      @calendar.events = events
    end

    render :action => 'index', :layout => false if request.xhr?

  end

  def projects
    @status = params[:status] ? params[:status].to_i : 1
    c = ARCondition.new(@status == 0 ? "status <> 0" : ["status = ?", @status])
    unless params[:name].blank?
      name = "%#{params[:name].strip.downcase}%"
      c << ["LOWER(identifier) LIKE ? OR LOWER(name) LIKE ?", name, name]
    end
    @projects = Project.find :all, :order => 'lft',
                                   :conditions => c.conditions

    render :action => "projects", :layout => false if request.xhr?
  end

  def plugins
    @plugins = Redmine::Plugin.all
  end

  # Loads the default configuration
  # (roles, trackers, statuses, workflow, enumerations)
  def default_configuration
    if request.post?
      begin
        Redmine::DefaultData::Loader::load(params[:lang])
        flash[:notice] = l(:notice_default_data_loaded)
      rescue Exception => e
        flash[:error] = l(:error_can_t_load_default_data, e.message)
      end
    end
    redirect_to :action => 'index'
  end

  def test_email
    raise_delivery_errors = ActionMailer::Base.raise_delivery_errors
    # Force ActionMailer to raise delivery errors so we can catch it
    ActionMailer::Base.raise_delivery_errors = true
    begin
      @test = Mailer.deliver_test(User.current)
      flash[:notice] = l(:notice_email_sent, User.current.mail)
    rescue Exception => e
      flash[:error] = l(:notice_email_error, e.message)
    end
    ActionMailer::Base.raise_delivery_errors = raise_delivery_errors
    redirect_to :controller => 'settings', :action => 'edit', :tab => 'notifications'
  end

  def info
    @db_adapter_name = ActiveRecord::Base.connection.adapter_name
    @checklist = [
      [:text_default_administrator_account_changed, User.default_admin_account_changed?],
      [:text_file_repository_writable, File.writable?(Attachment.storage_path)],
      [:text_plugin_assets_writable,   File.writable?(Engines.public_directory)],
      [:text_rmagick_available,        Object.const_defined?(:Magick)]
    ]
  end
end

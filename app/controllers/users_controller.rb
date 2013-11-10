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

class UsersController < ApplicationController
  layout 'admin'

#  before_filter :require_admin, :except => :show
  before_filter :require_admin, :except => [:show, :edit_abbonamento]
  before_filter :find_user, :only =>  [:show, :edit, :update, :destroy, :edit_membership, :destroy_membership]
  accept_api_auth :index, :show, :create, :update, :destroy
  before_filter :only_find_user, :only =>  [:edit_dati, :edit_abbonamento, :edit_fatture, :send_newsletter]

  helper :sort
  include SortHelper
  helper :custom_fields
  include CustomFieldsHelper

  def index
    sort_init 'login', 'asc'
    sort_update %w(login firstname lastname mail admin created_on last_login_on)

    case params[:format]
    when 'xml', 'json'
      @offset, @limit = api_offset_and_limit
    else
      @limit = per_page_option
    end

    scope = User
    scope = scope.in_group(params[:group_id].to_i) if params[:group_id].present?

    @status = params[:status] ? params[:status].to_i : 1
    c = ARCondition.new(@status == 0 ? "status <> 0" : ["status = ?", @status])

    unless params[:name].blank?
      name = "%#{params[:name].strip.downcase}%"
      c << ["LOWER(login) LIKE ? OR LOWER(firstname) LIKE ? OR LOWER(lastname) LIKE ? OR LOWER(mail) LIKE ?", name, name, name, name]
    end

    @user_count = scope.count(:conditions => c.conditions)
    @user_pages = Paginator.new self, @user_count, @limit, params['page']
    @offset ||= @user_pages.current.offset
    @users =  scope.find :all,
                        :order => sort_clause,
                        :conditions => c.conditions,
                        :limit  =>  @limit,
                        :offset =>  @offset

    respond_to do |format|
      format.html {
        @groups = Group.all.sort
        render :layout => !request.xhr?
      }
      format.api
    end
  end

  def show
    # show projects based on current user visibility
    @memberships = @user.memberships.all(:conditions => Project.visible_condition(User.current))

    events = Redmine::Activity::Fetcher.new(User.current, :author => @user).events(nil, nil, :limit => 10)
    @events_by_day = events.group_by(&:event_date)

    unless User.current.admin?
      if !@user.active? || (@user != User.current  && @memberships.empty? && events.empty?)
        render_404
        return
      end
    end

    respond_to do |format|
      format.html { render :layout => 'base' }
      format.api
    end
  end

  def new
    @user = User.new(:language => Setting.default_language, :mail_notification => Setting.default_notification_option)
    @auth_sources = AuthSource.find(:all)
  end

  verify :method => :post, :only => :create, :render => {:nothing => true, :status => :method_not_allowed }
  def create
    @user = User.new(:language => Setting.default_language, :mail_notification => Setting.default_notification_option)
    @user.safe_attributes = params[:user]
    @user.admin = params[:user][:admin] || false
    @user.login = params[:user][:login]
    @user.password, @user.password_confirmation = params[:user][:password], params[:user][:password_confirmation] unless @user.auth_source_id

    # TODO: Similar to My#account
    @user.pref.attributes = params[:pref]
    @user.pref[:no_self_feenotified] = (params[:no_self_notified] == '1')

    if @user.save
      @user.pref.save
      @user.notified_project_ids = (@user.mail_notification == 'selected' ? params[:notified_project_ids] : [])

      if Setting.fee?
        @user.control_state
      end

      Mailer.deliver_account_information(@user, params[:user][:password]) if params[:send_information]

      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_create)
          redirect_to(params[:continue] ?
            {:controller => 'users', :action => 'new'} :
            {:controller => 'users', :action => 'edit', :id => @user}
          )
        }
        format.api  { render :action => 'show', :status => :created, :location => user_url(@user) }
      end
    else
      @auth_sources = AuthSource.find(:all)
      # Clear password input
      @user.password = @user.password_confirmation = nil

      respond_to do |format|
        format.html { render :action => 'new' }
        format.api  { render_validation_errors(@user) }
      end
    end
  end

  def edit
    @auth_sources = AuthSource.find(:all)
    @membership ||= Member.new
  end

  verify :method => :put, :only => :update, :render => {:nothing => true, :status => :method_not_allowed }
  def update
    @user.admin = params[:user][:admin] if params[:user][:admin]
    @user.login = params[:user][:login] if params[:user][:login]
    if params[:user][:password].present? && (@user.auth_source_id.nil? || params[:user][:auth_source_id].blank?)
      @user.password, @user.password_confirmation = params[:user][:password], params[:user][:password_confirmation]
    end
    @user.safe_attributes = params[:user]
    # Was the account actived ? (do it before User#save clears the change)
    was_activated = (@user.status_change == [User::STATUS_REGISTERED, User::STATUS_ACTIVE])
    # TODO: Similar to My#account
    @user.pref.attributes = params[:pref]
    @user.pref[:no_self_notified] = (params[:no_self_notified] == '1')

    if @user.save
      @user.pref.save
      @user.notified_project_ids = (@user.mail_notification == 'selected' ? params[:notified_project_ids] : [])

      if Setting.fee?
        @user.control_state
      end

      if was_activated
        Mailer.deliver_account_activated(@user)
      elsif @user.active? && params[:send_information] && !params[:user][:password].blank? && @user.auth_source_id.nil?
        Mailer.deliver_account_information(@user, params[:user][:password])
      end

      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_update)
          redirect_to :back
        }
        format.api  { head :ok }
      end
    else
      @auth_sources = AuthSource.find(:all)
      @membership ||= Member.new
      # Clear password input
      @user.password = @user.password_confirmation = nil

      respond_to do |format|
        format.html { render :action => :edit }
        format.api  { render_validation_errors(@user) }
      end
    end
  rescue ::ActionController::RedirectBackError
    redirect_to :controller => 'users', :action => 'edit', :id => @user
  end

  verify :method => :delete, :only => :destroy, :render => {:nothing => true, :status => :method_not_allowed }
  def destroy
    @user.destroy
    respond_to do |format|
      format.html { redirect_to(users_url) }
      format.api  { head :ok }
    end
  end

  def edit_membership
    @membership = Member.edit_membership(params[:membership_id], params[:membership], @user)
    @membership.save if request.post?
    respond_to do |format|
      if @membership.valid?
        format.html { redirect_to :controller => 'users', :action => 'edit', :id => @user, :tab => 'memberships' }
        format.js {
          render(:update) {|page|
            page.replace_html "tab-content-memberships", :partial => 'users/memberships'
            page.visual_effect(:highlight, "member-#{@membership.id}")
          }
        }
      else
        format.js {
          render(:update) {|page|
             page.alert(l(:notice_failed_to_save_members, :errors => @membership.errors.full_messages.join(', ')))
          }
        }
      end
    end
  end

  #via js
  def edit_abbonamento
    @user.safe_attributes = params[:user]
    if request.post?
      @user.save
      @user.control_state
    end
    respond_to do |format|
      if @user.valid?
        format.html { redirect_to :controller => 'users', :action => 'edit', :id => @user, :tab => 'abbonamento' }
        format.js {
          render(:update) {|page|
            page.replace_html "tab-content-abbonamento", :partial => 'users/abbonamento'
            page.visual_effect(:highlight, "abbonamento-#{@user.id}")
          }
        }
      else
        format.js {
          render(:update) {|page|
            page.alert(l(:notice_failed_to_save_abbonamento, :errors => @user.errors.full_messages.join(', ')))
          }
        }
      end
    end
  end
  #via js
  def edit_dati
    @user.safe_attributes = params[:user]
    #@user.save if request.post?
    if request.post?
      @user.save
      @user.control_state
    end
    respond_to do |format|
      if @user.valid?
        format.html { redirect_to :controller => 'users', :action => 'edit', :id => @user, :tab => 'dati' }
        format.js {
          render(:update) {|page|
            page.replace_html "tab-content-dati", :partial => 'users/dati'
            page.visual_effect(:highlight, "dati-#{@user.id}")
          }
        }
      else
        format.js {
          render(:update) {|page|
            page.alert(l(:notice_failed_to_save_dati, :errors => @user.errors.full_messages.join(', ')))
          }
        }
      end
    end
  end
  #via js
  def edit_fatture
    @user.safe_attributes = params[:user]
    @user.save if request.post?
    respond_to do |format|
      if @user.valid?
        format.html { redirect_to :controller => 'users', :action => 'edit', :id => @user, :tab => 'fatture' }
        format.js {
          render(:update) {|page|
            page.replace_html "tab-content-fatture", :partial => 'users/fatture'
            page.visual_effect(:highlight, "fatture-#{@user.id}")
          }
        }
      else
        format.js {
          render(:update) {|page|
            page.alert(l(:notice_failed_to_save_fatture, :errors => @user.errors.full_messages.join(', ')))
          }
        }
      end
    end
  end

  #via js
  #in questa funzione possiamo
  # 1 vedere anteprima della newsletter --> via preview_controller con remote_form_for
  # 2 inviare via email la newsletter
  #Parameters: {"id"=>"17542", "action"=>"send_newsletter", "project"=>{"id"=>"308"}, "authenticity_token"=>"d0qcDDrxPu4tRQaWV0EQC9VO5f152OhGqfiIIb/K/d8=", "controller"=>"users", "_method"=>"put"}
  def send_newsletter
    @id = ((params[:project] && params[:project][:id]) || params[:project_id]).to_i
    #@project= Project.all_public_fs.find_by_id(@id.to_i)
    @project= Project.all_mail_fs.find_by_id(@id.to_i)
    @art = @project.issues.all_mail_fs  #Solo visibile MAIL
    #@htmlpartial = @user.newsletter_smtp(@edizione)
    @htmlpartial = render_to_string(
        :layout => false,
        :partial => 'editorial/edizione_smtp',
        :locals => { :id => @id, :project => @project, :art => @art, :user => @user }
      )

    act = params[:action]
    @msg = ''
    if act == 'send_newsletter'
      raise_delivery_errors = ActionMailer::Base.raise_delivery_errors
      # Force ActionMailer to raise delivery errors so we can catch it
      ActionMailer::Base.raise_delivery_errors = true
      @msg = 'Invio newsletter. '
      begin
        @tmail =  Mailer.deliver_newsletter(@user, @htmlpartial, @project)
        @msg += l(:notice_user_newsletter_email_sent, :edizione => @project.name, :date => @project.data_al,  :user => user.to_s)
        #@msg += " Risultato => " + @tmail (can't convert TMail::Mail into String)
      rescue Exception => e
        @msg += l(:notice_email_error, e.message)
      end
      ActionMailer::Base.raise_delivery_errors = raise_delivery_errors
    end

    respond_to do |format|
      if @user.valid?
        format.html { redirect_to :controller => 'users', :action => 'edit', :id => @user, :tab => 'newsletter' }
        format.js {
          render(:update) {|page|
            page.replace_html "tab-content-newsletter", :partial => 'users/newsletter'
            page.replace_html "news_preview", @htmlpartial
            page.visual_effect(:highlight, "newsletter-#{@user.id}")
            page.alert(@msg)
          }
        }
      else
        format.js {
          render(:update) {|page|
            page.alert(l(:notice_failed_to_send_newsletter, :errors => @user.errors.full_messages.join(', ')))
          }
        }
      end
    end
  end

  def destroy_membership
    @membership = Member.find(params[:membership_id])
    if request.post? && @membership.deletable?
      @membership.destroy
    end
    respond_to do |format|
      format.html { redirect_to :controller => 'users', :action => 'edit', :id => @user, :tab => 'memberships' }
      format.js { render(:update) {|page| page.replace_html "tab-content-memberships", :partial => 'users/memberships'} }
    end
  end

  private

  def find_user
    if params[:id] == 'current'
      require_login || return
      @user = User.current
    else
      @user = User.find(params[:id])
    end
  rescue ActiveRecord::RecordNotFound
    flash[:error] = l(:notice_user_not_found, {:id => params[:id]})
    redirect_to :controller => 'users', :action => 'index'
    render_404
  end

  def only_find_user
    @user = User.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:error] = l(:notice_user_not_found, {:id => params[:id]})
    redirect_to :controller => 'users', :action => 'index'
    render_404
  end
end

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

class PreviewsController < ApplicationController
  #before_filter :find_project, :except =>   [:newsletter, :norole, :nlemailed]
  before_filter :find_project, :only =>   [:issue, :articolo, :news]
  before_filter :find_user_project, :only =>   [:newsletter]
  before_filter :find_newsletter, :only =>   [:nlemailed, :newsletter_nl]

  #include FeesHelper #getdate get_role_css

  def issue
    @issue = @project.issues.find_by_id(params[:id]) unless params[:id].blank?
    if @issue
      @attachements = @issue.attachments
      @description = params[:issue] && params[:issue][:description]
      #Attenzione con HTML non serve --> remare questo if
      if @description && @description.gsub(/(\r?\n|\n\r?)/, "\n") == @issue.description.to_s.gsub(/(\r?\n|\n\r?)/, "\n")
        @description = nil
      end
      @notes = params[:notes]
    else
      @description = (params[:issue] ? params[:issue][:description] : nil)
    end
    render :layout => false
  end

  def articolo
    @articolo = @project.issues.find_by_id(params[:id]) unless params[:id].blank?
    if @articolo
      @attachements = @articolo.attachments
      @description = params[:issue] && params[:issue][:description]
      @notes = params[:notes]
    else
      @description = (params[:issue] ? params[:issue][:description] : nil)
    end
    render :layout => false
  end

  #Newsletter  grafica della newsletter
  def newsletter
    @art = @project.issues.all_mail_fs  #Solo visibile MAIL
    render :layout => false, :partial => 'editorial/edizione_smtp'
  end

  #Newsletter  grafica della newsletter
  def newsletter_nl
    @project = @newsletter.project
    @art = @project.issues.all_mail_fs  #Solo visibile MAIL
    render :layout => false, :partial => 'editorial/edizione_smtp'
  end

  #Newsletter invii fatti o da fare o in errore
  def nlemailed
    @type = (params[:type].present? ? params[:type] : 'notice')
    case @type
    when 'error'
      @nl_users = @newsletter.newsletter_users.find(:all,
        :conditions => ['sended = false AND information_id is not null '],
        #:limit => 10,
        #:include => [ :status, :project, :tracker ],
        :order => "#{NewsletterUser.table_name}.updated_at DESC")
    when 'warning'
      @nl_users = @newsletter.newsletter_users.find(:all,
        :conditions => ['sended = false AND information_id is null'],
        #:limit => 10,
        #:include => [ :status, :project, :tracker ],
        :order => "#{NewsletterUser.table_name}.updated_at DESC")
    else #'notice'
      @nl_users = @newsletter.newsletter_users.find(:all,
        :conditions => { :sended => true },
        #:limit => 10,
        #:include => [ :status, :project, :tracker ],
        :order => "#{NewsletterUser.table_name}.updated_at DESC")
    end
    #render :layout => false, :partial => 'newsletter_users/users_newsletter_emailed' #undefined method `get_role_css' for #<ActionView::Base:0xb51cc0b8>
    render :layout => false, :partial => 'newsletters/users_newsletter_emailed'
    #, :locals => {:users_nl => @nl_users}
  end

  def news
    @text = (params[:news] ? params[:news][:description] : nil)
    render :partial => 'common/preview'
  end

  def norole
    @users = User.all(:conditions => {:role_id => nil || 2})
    render :layout => false, :partial => 'fees/users_unassigned'
  end

  private

    def find_project
      project_id = (params[:issue] && params[:issue][:project_id]) || params[:project_id]
      @project = Project.find(project_id)
    rescue ActiveRecord::RecordNotFound
      render_404
    end

    def find_user_project
      @id = ((params[:project] && params[:project][:id]) || params[:project_id]).to_i

      #HOME
      #@project= Project.all_public_fs.find_by_id(@id.to_i)
      #MAIL
      @project= Project.all_mail_fs.find_by_id(@id.to_i)

      user_id = (params[:user] && params[:user][:id]) || params[:user_id]
      @user = User.find(user_id) if (user_id && (user_id.to_i > 0))
      @user = User.Current if @user.nil?
    rescue ActiveRecord::RecordNotFound
      render_404
    end

    def find_newsletter
      @newsletter = Newsletter.find_by_id(params[:id].to_i)
    rescue ActiveRecord::RecordNotFound
      render_404
    end

end

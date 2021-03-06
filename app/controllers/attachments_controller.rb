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

class AttachmentsController < ApplicationController
  before_filter :find_project
  before_filter :file_readable, :except => [:destroy]
  before_filter :read_authorize, :except => [:destroy, :show_fs]
  before_filter :delete_authorize, :only => :destroy

  accept_api_auth :show, :download

  def show
    respond_to do |format|
      format.html {
        if @attachment.is_diff?
          @diff = File.new(@attachment.diskfile, "rb").read
          @diff_type = params[:type] || User.current.pref[:diff_type] || 'inline'
          @diff_type = 'inline' unless %w(inline sbs).include?(@diff_type)
          # Save diff type as user preference
          if User.current.logged? && @diff_type != User.current.pref[:diff_type]
            User.current.pref[:diff_type] = @diff_type
            User.current.preference.save
          end
          render :action => 'diff'
        elsif @attachment.is_text? && @attachment.filesize <= Setting.file_max_size_displayed.to_i.kilobyte
          @content = File.new(@attachment.diskfile, "rb").read
          render :action => 'file'
        else
          download
        end
      }
      format.api
    end
  end

#inizio   attachments per il front end sandro
  def show_fs
    doaction = false
    if  @attachment.container.is_a?(Issue)
      if @attachment.container.se_protetto
        unless  User.current.isregistered? && @attachment.container.section.protetto
          doaction = true
        end
      else
        doaction = true
      end
    else
      doaction = true
    end
    if doaction
      respond_to do |format|
        format.html {
          if @attachment.is_diff?
            @diff = File.new(@attachment.diskfile, "rb").read
            @diff_type = params[:type] || User.current.pref[:diff_type] || 'inline'
            @diff_type = 'inline' unless %w(inline sbs).include?(@diff_type)
            # Save diff type as user preference
            if User.current.logged? && @diff_type != User.current.pref[:diff_type]
              User.current.pref[:diff_type] = @diff_type
              User.current.preference.save
            end
            render :action => 'diff'
          elsif @attachment.is_text? && @attachment.filesize <= Setting.file_max_size_displayed.to_i.kilobyte
            @content = File.new(@attachment.diskfile, "rb").read
            render :action => 'file'
          else
            download
          end
        }
        format.api
      end
    else
      flash[:alert] = l(:notice_not_valid_abbo)
      #redirect_to :back
      redirect_back_or_default(editorial_url)
    end
  end

  def is_section_not_restricted?
    # puts "regist -----------> " + User.current.isregistered?.to_s + " ////protet. " + @attachment.container.section.protetto.to_s
    if  @attachment.container.is_a?(Issue)
      if  User.current.isregistered? && @attachment.container.section.protetto
        return false
      end
    end
    true
  end

#fine   attachments sandro

  def download
    if @attachment.container.is_a?(Version) || @attachment.container.is_a?(Project)
      @attachment.increment_download
    end

    # images are sent inline
    send_file @attachment.diskfile, :filename => filename_for_content_disposition(@attachment.filename),
              :type => detect_content_type(@attachment),
              :disposition => (@attachment.image? || @attachment.pdf? ? 'inline' : 'attachment')
             #:disposition => (@attachment.image? ? 'inline' : 'attachment')

  end

  verify :method => :delete, :only => :destroy

  def destroy
    # Make sure association callbacks are called
    @attachment.container.attachments.delete(@attachment)
    redirect_to :back
  rescue ::ActionController::RedirectBackError
    redirect_to :controller => 'projects', :action => 'show', :id => @project
  end

  private
  def find_project
    @attachment = Attachment.find(params[:id])
    # Show 404 if the filename in the url is wrong
    raise ActiveRecord::RecordNotFound if params[:filename] && params[:filename] != @attachment.filename
    @project = @attachment.project
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  # Checks that the file exists and is readable
  def file_readable
    @attachment.readable? ? true : (params[:action]=='show_fs') ? render_404_fs : render_404
  end

  def read_authorize
    @attachment.visible? ? true : deny_access
  end

  def delete_authorize
    @attachment.deletable? ? true : deny_access
  end

  def detect_content_type(attachment)
    content_type = attachment.content_type
    if content_type.blank?
      content_type = Redmine::MimeType.of(attachment.filename)
    end
    content_type.to_s
  end
end

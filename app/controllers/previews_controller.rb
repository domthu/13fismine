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

class PreviewsController < ApplicationController
  before_filter :find_project, :except =>   [:newsletter]
  before_filter :find_user_project, :only =>   [:newsletter]

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
    @art = @project.issues.all(:order => "#{Section.table_name}.top_section_id DESC", :include => [:section => :top_section])
    render :layout => false, :partial => 'editorial/edizione_smtp'
  end

  def news
    @text = (params[:news] ? params[:news][:description] : nil)
    render :partial => 'common/preview'
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
    @project= Project.all_public_fs.find_by_id(@id.to_i)
    user_id = (params[:user] && params[:user][:id]) || params[:user_id]
    @user = User.find(user_id) if (user_id && (user_id.to_i > 0))
    @user = User.Current if @user.nil?
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end

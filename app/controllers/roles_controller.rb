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

class RolesController < ApplicationController
  layout 'admin'

  before_filter :require_admin

  verify :method => :post, :only => [ :destroy ],
         :redirect_to => { :action => :index }

  include FeesHelper  #Domthu  FeeConst

  def index
    @role_pages, @roles = paginate :roles, :per_page => 25, :order => 'builtin, position'
    render :action => "index", :layout => false if request.xhr?
  end

  def new
    # Prefills the form with 'Non member' role permissions
    @role = Role.new(params[:role] || {:permissions => Role.non_member.permissions})
    if request.post? && @role.save
      # workflow copy
      if !params[:copy_workflow_from].blank? && (copy_from = Role.find_by_id(params[:copy_workflow_from]))
        @role.workflows.copy(copy_from)
      end
      flash[:notice] = l(:notice_successful_create)
      redirect_to :action => 'index'
    else
      @permissions = @role.setable_permissions
      @roles = Role.find :all, :order => 'builtin, position'
    end
  end

  def edit
    @role = Role.find(params[:id])
    if request.post? and @role.update_attributes(params[:role])
      flash[:notice] = l(:notice_successful_update)
      redirect_to :action => 'index'
    else
      @permissions = @role.setable_permissions
    end
  end

  def destroy
    #Per rendere un ruolo da sistema impostare sul database il builtin > 0
    @role = Role.find(params[:id])
    #ROLE_MANAGER      = 3  #Manager<br />
    #ROLE_AUTHOR       = 4  #Redattore  <br />
    #ROLE_VIP          = 10 #Invitato Gratuito<br />
    #ROLE_ABBONATO     = 6  #Abbonato user.data_scadenza > (today - Setting.renew_days)<br />
    #ROLE_REGISTERED   = 9  #Ospite periodo di prova durante Setting.register_days<br />
    #ROLE_RENEW=11
    #ROLE_EXPIRED=7
    #ROLE_ARCHIVIED=8
    if Setting.fee? and FeeConst::CAN_BACK_END_ROLES.include? @role.id
      flash[:error] = l(:error_can_not_remove_role_for_fee_management)
    else
      @role.destroy
    end
    redirect_to :action => 'index'
  rescue
    flash[:error] =  l(:error_can_not_remove_role)
    redirect_to :action => 'index'
  end

  def report
    @roles = Role.find(:all, :order => 'builtin, position')
    @permissions = Redmine::AccessControl.permissions.select { |p| !p.public? }
    if request.post?
      @roles.each do |role|
        role.permissions = params[:permissions][role.id.to_s]
        role.save
      end
      flash[:notice] = l(:notice_successful_update)
      redirect_to :action => 'index'
    end
  end
end

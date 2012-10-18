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

class WelcomeController < ApplicationController
  caches_action :robots

#before_filter: autorize

#domthu permission :access_back_end, :welcome => :index, :require => :loggedin
#add permission to control navigation role
#Admin e power_user sono definiti da campi della tabella User
#RUOLI
#MANAGER --> ok
#REDATTORE --> ok
#ABBONATO --> KAPPAO
#Anomimo --> KAPPAO
#GUEST --> KAPPAO
#SCADUTI --> KAPPAO
#ARCHIVIATI --> KAPPAO

  def index
    #domthu redirect
    if (not User.current.logged?) || (not User.current.allowed_to?(:access_back_end, nil, :global => true))
      redirect_to(editoriale_path + '1' ) && return
    #  redirect_to(editoriale_url) && return
    end
    @news = News.latest User.current
    @projects = Project.latest User.current
  end

  def robots
    @projects = Project.all_public.active
    render :layout => false, :content_type => 'text/plain'
  end
end

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

class WatchersController < ApplicationController
  before_filter :find_project
  before_filter :find_watcher_user, :only => [:watch_for, :unwatch_for]
  before_filter :find_all_watchers, :only => [:watch_all, :unwatch_all]
  before_filter :require_login, :check_project_privacy, :only => [:watch, :unwatch, :watch_for, :unwatch_for]
  before_filter :authorize, :only => [:new, :destroy]

  verify :method => :post,
         :only => [ :watch, :unwatch, :watch_for, :unwatch_for ],
         :render => { :nothing => true, :status => :method_not_allowed }

  def watch
    if @watched.respond_to?(:visible?) && !@watched.visible?(User.current)
      render_403
    else
      set_watcher(User.current, true)
    end
  end
  def watch_for
    if @watched.respond_to?(:visible?) && !@watched.visible?(@user)
      render_403
    else
      set_watcher(@user, true)
    end
  end
  def watch_all
    @arr = []
    for usr in @users_all do
      #next unless !@watched.visible?(usr)
      #puts "user(" + usr.id.to_s + ") --> " + usr.name
      if !@watched.watched_by?(usr)
        @watched.set_watcher(usr, true)
        @arr.push(usr)
      end
    end
    respond_to do |format|
      format.html { redirect_to :back }
      format.js do
        render(:update) do |page|
          for usr in @arr do
            c = watcher_css(@watched, usr)
            page.select(".#{c}").each do |item|
              page.replace_html item, watcher_link(@watched, usr)
            end
          end
        end
      end
    end
  rescue ::ActionController::RedirectBackError
    render :text => (watching ? 'Watcher added.' : 'Watcher removed.'), :layout => true
  end

  def unwatch
    set_watcher(User.current, false)
  end
  def unwatch_for
    set_watcher(@user, false)
  end
  def unwatch_all
    @arr = []
    for usr in @users_all do
      next unless usr
      #puts "user(" + usr.id.to_s + ") --> " + usr.name
      if @watched.watched_by?(usr)
        @watched.set_watcher(usr, false)
        @arr.push(usr)
      end
    end
    respond_to do |format|
      format.html { redirect_to :back }
      format.js do
        render(:update) do |page|
          for usr in @arr do
            c = watcher_css(@watched, usr)
            page.select(".#{c}").each do |item|
              page.replace_html item, watcher_link(@watched, usr)
            end
          end
        end
      end
    end
  rescue ::ActionController::RedirectBackError
    render :text => (watching ? 'Watcher added.' : 'Watcher removed.'), :layout => true
  end

  def new
    @watcher = Watcher.new(params[:watcher])
    @watcher.watchable = @watched
    @watcher.save if request.post?
    respond_to do |format|
      format.html { redirect_to :back }
      format.js do
        render :update do |page|
          page.replace_html 'watchers', :partial => 'watchers/watchers', :locals => {:watched => @watched}
        end
      end
    end
  rescue ::ActionController::RedirectBackError
    render :text => 'Watcher added.', :layout => true
  end

  def destroy
    @watched.set_watcher(User.find(params[:user_id]), false) if request.post?
    respond_to do |format|
      format.html { redirect_to :back }
      format.js do
        render :update do |page|
          page.replace_html 'watchers', :partial => 'watchers/watchers', :locals => {:watched => @watched}
        end
      end
    end
  end

private
  def find_project
    klass = Object.const_get(params[:object_type].camelcase)
    return false unless klass.respond_to?('watched_by')
    @watched = klass.find(params[:object_id])
    @project = @watched.project
  rescue
    render_404
  end

  def find_watcher_user
    @user = User.find(params[:user_id])
  rescue
    render_404
  end
  def find_all_watchers
    @users_all = @project.users
  rescue
    render_404
  end

  def set_watcher(user, watching)
    @watched.set_watcher(user, watching)
    respond_to do |format|
      format.html { redirect_to :back }
      format.js do
        render(:update) do |page|
          c = watcher_css(@watched, user)
          page.select(".#{c}").each do |item|
            page.replace_html item, watcher_link(@watched, user)
          end
        end
      end
    end
  rescue ::ActionController::RedirectBackError
    render :text => (watching ? 'Watcher added.' : 'Watcher removed.'), :layout => true
  end
end

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

class NewsObserver < ActiveRecord::Observer
  include Redmine::I18n #translation l(:words)
  def after_create(news)
    #Mailer.deliver_news_added(news) if Setting.notified_events.include?('news_added')
    # Force ActionMailer to raise delivery errors so we can catch it
    raise_delivery_errors = ActionMailer::Base.raise_delivery_errors
    ActionMailer::Base.raise_delivery_errors = true
    begin
      Mailer.deliver_news_added(news) if Setting.notified_events.include?('news_added')
    rescue Exception => e
      Rails.logger.error l(:notice_email_error, e.message) #if logger
      #flash[:error] = l(:notice_email_error, e.message) undefined local variable or method `flash' for #<NewsObserver:0xb634f6a0>
      #raise e
    end
    ActionMailer::Base.raise_delivery_errors = raise_delivery_errors
  end
end

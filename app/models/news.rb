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

class News < ActiveRecord::Base
  include Redmine::SafeAttributes
  belongs_to :project
  belongs_to :author, :class_name => 'User', :foreign_key => 'author_id'
  has_many :comments, :as => :commented, :dependent => :delete_all, :order => "created_on"
  #Un quesito puo generare un articolo (o più di uno)
  has_many :issues, :order => "#{Issue.table_name}.created_on DESC", :include => [:status, :tracker, {:section => :top_section} ]  #, :dependent => :destroy

  validates_presence_of :title, :description
  validates_length_of :title, :maximum => 60
  validates_length_of :summary, :maximum => 255

  acts_as_searchable :columns => ['title', 'summary', "#{table_name}.description"], :include => :project
  acts_as_event :url => Proc.new {|o| {:controller => 'news', :action => 'show', :id => o.id}}
  acts_as_activity_provider :find_options => {:include => [:project, :author]},
                            :author_key => :author_id
  acts_as_watchable

  after_create :add_author_as_watcher

  named_scope :visible, lambda {|*args| {
    :include => :project,
    :conditions => Project.allowed_to_condition(args.shift || User.current, :view_news, *args)
  }}

  named_scope :issues_visible_fs,
    :include => [{:issue => :project}],
    :conditions => ["#{Project.table_name}.status=#{Project::STATUS_ACTIVE} AND #{Project.table_name}.is_public => true AND #{Issue.table_name}.se_visible_web => true"]

  safe_attributes 'title',
     'summary',
     'description',
     'status_id',
     'causale'

  def status_fs
    if self.status_id.nil?
     "Richiesta in attesa, Modificabile"
    else
      case self.status_id
        when FeeConst::QUESITO_STATUS_WAIT #=  1 #IN ATTESA - RICHIESTA
          "Richiesta in attesa, Modificabile"
        when FeeConst::QUESITO_STATUS_FAST_REPLY #= 2 #RISPOSTA VELOCE TRAMITE NEWS
          "risposto : " + self.causale.to_s
        when FeeConst::QUESITO_STATUS_ISSUES_REPLY #=   3 #RISPOSTA TRAMITE ARTICOLO/I
          "Accettato " + (self.issues.empty? ? " 0 risposta" : " " + self.issues.count.to_s + " risposte.")
        else
          "Status non conosciuto"
      end
    end
  end
  def status_fs_number
    if self.status_id.nil?
        FeeConst::QUESITO_STATUS_WAIT
      else
        case self.status_id
          when FeeConst::QUESITO_STATUS_WAIT #=  1 #IN ATTESA - RICHIESTA
            FeeConst::QUESITO_STATUS_WAIT
          when FeeConst::QUESITO_STATUS_FAST_REPLY #= 2 #RISPOSTA VELOCE TRAMITE NEWS
            FeeConst::QUESITO_STATUS_FAST_REPLY
          when FeeConst::QUESITO_STATUS_ISSUES_REPLY #=   3 #RISPOSTA TRAMITE ARTICOLO/I
            self.issues.empty? ? 3:4
          else
          9
        end
      end
    end

  def visible?(user=User.current)
    !user.nil? && user.allowed_to?(:view_news, project)
  end

  # returns latest news for projects visible by user
  def self.latest(user = User.current, count = 5)
    find(:all, :limit => count, :conditions => Project.allowed_to_condition(user, :view_news), :include => [ :author, :project ], :order => "#{News.table_name}.created_on DESC")
  end

  # returns latest news for public area
  def self.latest_fs(user = User.current, count = 5)
    #:conditions => [ "catchment_areas_id = ?", params[:id]]
    #:conditions => Project.is_public == true  -->  method missing
    #:conditions => projects.is_public = 1
    #:conditions => Project.is_public = 1
    find(:all, :limit => count, :conditions => "#{Project.table_name}.is_public = 1", :include => [ :author, :project ], :order => "#{News.table_name}.created_on DESC")
  end

  def abbr_name
    #formatter from Setting.user_format
    "N°" + self.id.to_s + " da " + self.author.name()
  end

  private

  def add_author_as_watcher
    Watcher.create(:watchable => self, :user => author)
  end
end

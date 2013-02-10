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
  has_many :issues, :order => "#{Issue.table_name}.created_on DESC", :include => [:status, :tracker, {:section => :top_section}] #, :dependent => :destroy

  validates_presence_of :title, :description
  validates_length_of :title, :maximum => 60
  validates_length_of :summary, :maximum => 255

  acts_as_searchable :columns => ['title', 'summary', "#{table_name}.description"], :include => :project
  acts_as_event :url => Proc.new { |o| {:controller => 'news', :action => 'show', :id => o.id} }
  acts_as_activity_provider :find_options => {:include => [:project, :author]},
                            :author_key => :author_id
  acts_as_watchable

  after_create :add_author_as_watcher

  named_scope :visible, lambda { |*args| {
      :include => :project,
      :conditions => Project.allowed_to_condition(args.shift || User.current, :view_news, *args)
  } }

=begin
<<<<<<< HEAD
  named_scope :issues_visible_fs,
              :include => [{:issue => :project}],
              :conditions => ["#{Project.table_name}.status=#{Project::STATUS_ACTIVE} AND #{Project.table_name}.is_public => true AND #{Issue.table_name}.se_visible_web => true"]
=======
=end
  named_scope :all_public_fs, {
      :include => [{:issues, :project}],
      :conditions => "#{Project.table_name}.status = #{Project::STATUS_ACTIVE} AND #{Project.table_name}.is_public = true AND #{Issue.table_name}.se_visible_web = true AND #{Project.table_name}.identifier = '#{FeeConst::QUESITO_KEY}'",
      :order => "#{table_name}.created_on DESC"}

  named_scope :all_quesiti_fs, {
      :include => [:project, :issues],
      :conditions => "#{Project.table_name}.identifier = '#{FeeConst::QUESITO_KEY}'",
      :order => "#{table_name}.created_on DESC"}

  #------------------------
  safe_attributes 'title',
                  'summary',
                  'description',
                  'status_id',
                  'causale'

  def public_fs1
     n= self.issues.all_public_fs.count.to_s
      return n
  end
  def test_all_quesiti_fs
    self.issues.all_quesiti_fs.count.to_s
  end


  def status_fs
    if self.status_id.nil?
      "Richiesta in attesa, Modificabile"
    else
      case self.status_id
        when FeeConst::QUESITO_STATUS_WAIT #=  1 #IN ATTESA - RICHIESTA
          "<h3>Il suo quesito verrà esaminato dalla redazione appena possibile.</h3><p>Se lo desidera puo' eliminarlo oppure apportare modifiche</p>"
        when FeeConst::QUESITO_STATUS_FAST_REPLY #= 2 #RISPOSTA VELOCE TRAMITE NEWS
          "<h3>Abbiamo risposto al suo quesito.</h3><p>Grazie per averci contattato.</p>"
        when FeeConst::QUESITO_STATUS_ISSUES_REPLY #=   3 #RISPOSTA TRAMITE ARTICOLO/I
         # pub =  self.issues.all_public_fs.count
         # nop =  self.issues.all_quesiti_fs.count
          pub=2
          nop=3
          if nop == 0 #se non ha niente caso strano perchè si dovrebbe creare un articolo di risposta subito...
            "<h3>Il suo quesito è stato accettato ma non ha avuto ancora risposta.</h3><p>Appena possibile le forniremo una risposta tramite uno o più articoli che trattano argomenti attinenti al suo quesito, grazie.</p>"
          else
            if pub == 0 #se non è stato pubblicato ...
              "<h3>Risponderemo presto al suo quesito pubblicando " + (nop == 1 ? "un articolo." : nop.to_s  + " articoli.") + "</h3>"
              "<p>Il suo quesito è stato giudicato di interesse collettivo, stiamo preparando " + (nop == 1 ? "un articolo" : nop.to_s  + " articoli") + "che tratteranno gli argomenti da lei richiesti. Grazie per la collaborazione.</p>"
            else
              n = nop - pub
              "<h3>Abbiamo risposto al suo quesito pubblicando " + (pub == 1 ? "un articolo." : pub.to_s + " articoli.") + "</h3>"
              "<p>Il suo quesito è stato giudicato di interesse collettivo, abbiamo quindi deciso di pubblicare " + (pub == 1 ? "un articolo" : pub.to_s  + " articoli") + "che trattano gli argomenti da lei richiesti. Grazie per la collaborazione.</p>"
              if n > 0
                "<p>E' in previsione l'uscita di " + (n == 1 ? "un ulteriore articolo" : "altri " + n.to_s  + " articoli") + " per rispondere a tutti gli argomenti da lei sollecitati, a presto.</p>"
              end
            end
          end
        else
          "Status non conosciuto"
      end
    end
  end

  def get_state_css
    if self.status_id.nil?
      "domand_wait"
    else
      case self.status_id
        when FeeConst::QUESITO_STATUS_WAIT #=  1 #IN ATTESA - RICHIESTA
          "domand_wait"
        when FeeConst::QUESITO_STATUS_FAST_REPLY #= 2 #RISPOSTA VELOCE TRAMITE NEWS
          "domand_ko"
        when FeeConst::QUESITO_STATUS_ISSUES_REPLY #=   3 #RISPOSTA TRAMITE ARTICOLO/I
          "domand_ok"
        else
          "domand_x"
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
          if self.issues.empty?
            3
          else
            4
          end
        else
          9
      end
    end
  end

  def status_fs_icons_fe
    if self.status_id.nil?
      "<div class='fs-quesiti-status-icon fs-quesiti-status-1'></div>"
    else
      case self.status_id
        when FeeConst::QUESITO_STATUS_WAIT #=  1 #IN ATTESA - RICHIESTA
          "<div class='fs-quesiti-status-icon fs-quesiti-status-1'></div>"
        when FeeConst::QUESITO_STATUS_FAST_REPLY #= 2 #RISPOSTA VELOCE TRAMITE NEWS
          "<div class='fs-quesiti-status-icon fs-quesiti-status-2'></div>"
        when FeeConst::QUESITO_STATUS_ISSUES_REPLY #=   3 #RISPOSTA TRAMITE ARTICOLO/I
          if self.issues.all_public_fs.count < 1
            "<div class='fs-quesiti-status-icon fs-quesiti-status-3'></div>"
          else
            "<div class='fs-quesiti-status-icon fs-quesiti-status-4'></div>"
          end
        else
          9
      end
    end
  end

  def quesito_new_default_title(user=User.current)
    if user.nil?
      'Utente non identificato '
    else
      s = 'Quesito posto dall\'utente [n°'
      s += User.current.id.to_s + '] '
      s += User.current.firstname? ? User.current.firstname.to_s : ''
      s += User.current.lastname? ? User.current.lastname.to_s : ''
      return s
    end
  end


  def visible?(user=User.current)
    !user.nil? && user.allowed_to?(:view_news, project)
  end

  def is_quesito?
    if self.project.identifier == FeeConst::QUESITO_KEY
      true
    else
      false
    end
  end

  def is_online?
    if self.status_id == FeeConst::QUESITO_STATUS_FAST_REPLY
      true
    else
      false
    end
  end

  # returns latest news for projects visible by user
  def self.latest(user = User.current, count = 5)
    find(:all, :limit => count, :conditions => Project.allowed_to_condition(user, :view_news), :include => [:author, :project], :order => "#{News.table_name}.created_on DESC")
  end

  # returns latest news for public area
  def self.latest_fs(user = User.current, count = 5)
    #:conditions => [ "catchment_areas_id = ?", params[:id]]
    #:conditions => Project.is_public == true  -->  method missing
    #:conditions => projects.is_public = 1
    #:conditions => Project.is_public = 1
    find(:all, :limit => count, :conditions => "#{Project.table_name}.is_public = 1", :include => [:author, :project], :order => "#{News.table_name}.created_on DESC")
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

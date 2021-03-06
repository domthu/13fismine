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

class News < ActiveRecord::Base
  include Redmine::SafeAttributes
  belongs_to :project
  belongs_to :author, :class_name => 'User', :foreign_key => 'author_id'
  has_many :comments, :as => :commented, :dependent => :delete_all, :order => "created_on"
  #Un quesito puo generare un articolo (o più di uno)
  has_many :issues, :order => "#{Issue.table_name}.created_on DESC", :include => [:status, :tracker, {:section => :top_section}] #, :dependent => :destroy

  validates_presence_of :title, :description
  validates_length_of :title, :maximum => 124
  validates_length_of :summary, :maximum => 255

  acts_as_searchable :columns => ['title', "#{table_name}.summary", "#{table_name}.description"], :include => :project
  acts_as_event :url => Proc.new { |o| {:controller => 'news', :action => 'show', :id => o.id} }
  acts_as_activity_provider :find_options => {:include => [:project, :author]},
                            :author_key => :author_id
  acts_as_watchable

  after_create :add_author_as_watcher

  named_scope :visible, lambda { |*args| {
      :include => :project,
      :conditions => Project.allowed_to_condition(args.shift || User.current, :view_news, *args)
  } }

  named_scope :all_public_fs, {
      :include => [{:issues, :project}],
      :conditions => "#{Project.table_name}.status = #{Project::STATUS_ACTIVE} AND #{Project.table_name}.is_public = true AND #{Issue.table_name}.se_visible_web = true AND #{Project.table_name}.identifier <> '#{FeeConst::QUESITO_KEY}'",
      :order => "#{Project.table_name}.id DESC , #{table_name}.created_on DESC"}

  named_scope :all_quesiti_fs, {
      :include => [{:project, :issues}],
      :conditions => "#{Project.table_name}.identifier = '#{FeeConst::QUESITO_KEY}'",
      :order => "#{Project.table_name}.id DESC , #{table_name}.created_on DESC"}

  #------------------------
  safe_attributes 'title',
                  'summary',
                  'description',
                  'status_id',
                  'reply'

  def public_fs_issues
    self.issues.all_public_fs.count.to_s

  end

  def test_all_quesiti_fs
    self.issues.all_quesiti_fs.count.to_s
  end


  def quesito_status_fs_text

    if self.status_id.nil?
      "Richiesta in attesa, Modificabile"
    else
      case self.status_id
        when FeeConst::QUESITO_STATUS_WAIT #=  1 #IN ATTESA - RICHIESTA
          "<h3 class=" + self.get_state_css + ">Il suo quesito verrà esaminato dalla redazione appena possibile.</h3><p>Se lo desidera puo' eliminarlo oppure apportare modifiche</p>"
        when FeeConst::QUESITO_STATUS_FAST_REPLY #= 2 #RISPOSTA VELOCE TRAMITE NEWS
          "<h3 class=" + self.get_state_css + ">Abbiamo risposto al suo quesito.</h3><p>Grazie per averci contattato.</p>"
        when FeeConst::QUESITO_STATUS_ISSUES_REPLY #=   3 #RISPOSTA TRAMITE ARTICOLO/I
          pub = self.issues.all_public_fs.count
          nop = self.issues.count
          if nop == 0 #se non ha niente caso strano perchè si dovrebbe creare un articolo di risposta subito...
            "<h3 class=" + self.get_state_css + ">Il suo quesito è stato accettato ma non ha avuto ancora risposta.</h3><p>Appena possibile le forniremo una risposta tramite uno o più articoli che trattano argomenti attinenti al suo quesito, grazie.</p>"
          else
            if pub == 0 #se non è stato pubblicato ...
              "<h3 class=" + self.get_state_css + ">Risponderemo presto al suo quesito</h3>
              <p>Il suo quesito è stato preso in considerazione, stiamo preparando " + (nop == 1 ? "una risposta alla sua domanda" : nop.to_s + " risposte alle sue domande") + ", grazie a presto!  .</p>"
            else
              n = nop - pub
              s = "<h3 class=" + self.get_state_css + ">Abbiamo risposto al suo quesito pubblicando " + (pub == 1 ? "un articolo." : pub.to_s + " articoli.") + "</h3>
              <p>Il suo quesito è stato giudicato di interesse collettivo, abbiamo quindi deciso di pubblicare " + (pub == 1 ? "un articolo" : pub.to_s + " articoli") + " per rispondere alle sue domande. "
              if n > 0
                s += " E' in previsione l'uscita di <span style='text-decoration:underline;'> " + (n == 1 ? "un ulteriore articolo" : "altri " + n.to_s + " articoli") + "</span> per rispondere a tutti gli argomenti da lei sollecitati, a presto!. "
              end
              s += "</p>"
              return s
            end
          end
        else
          "Status non conosciuto"
      end
    end
  end

  def quesito_status_fs_text_be

    if self.status_id.nil?
      "<h3>Quesito nuovo, non assegnato/risposto.</h3>"
    else
      case self.status_id
        when FeeConst::QUESITO_STATUS_WAIT #=  1 #IN ATTESA - RICHIESTA
          "<h3 class=" + self.get_state_css + ">Quesito nuovo, non assegnato/risposto.</h3>"
        when FeeConst::QUESITO_STATUS_FAST_REPLY #= 2 #RISPOSTA VELOCE TRAMITE NEWS
          "<h3 class=" + self.get_state_css + ">Risposta rapida al quesito.</h3>"
        when FeeConst::QUESITO_STATUS_ISSUES_REPLY #=   3 #RISPOSTA TRAMITE ARTICOLO/I
          pub = self.issues.all_public_fs.count
          nop = self.issues.count
          if nop == 0 #se non ha niente caso strano perchè si dovrebbe creare un articolo di risposta subito...
            "<h3 class=" + self.get_state_css + ">Il quesito è stato accettato.</h3>"
          else
            if pub == 0 #se non è stato pubblicato ...
              "<h3 class=" + self.get_state_css + "> " + (nop == 1 ? "Creato 1 articolo per la risposta, stato: non pubblicato" : "Creati " + nop.to_s + " per la risposta, stato: non pubblicati") + ".</h3>"
            else
              n = nop - pub
              s = "<h3 class=" + self.get_state_css + ">Articoli di riposta al quesito:" + (pub == 1 ? " 1 pubblicato " : pub.to_s + " pubblicati ")
              if n > 0
                s += (n == 1 ? " 1 articolo non pubblicato" : n.to_s + " articoli non pubblicati") + "</h3> "
              end
              return s
            end
          end
        else
          "Status non conosciuto"
      end
    end
  end

  def quesito_status_fs_number
    if self.status_id.nil?
      FeeConst::QUESITO_STATUS_WAIT
    else
      case self.status_id
        when FeeConst::QUESITO_STATUS_WAIT #=  1 #IN ATTESA - RICHIESTA
          FeeConst::QUESITO_STATUS_WAIT
        when FeeConst::QUESITO_STATUS_FAST_REPLY #= 2 #RISPOSTA VELOCE TRAMITE NEWS
          FeeConst::QUESITO_STATUS_FAST_REPLY
        when FeeConst::QUESITO_STATUS_ISSUES_REPLY #=   3 #RISPOSTA TRAMITE ARTICOLO/I
          FeeConst::QUESITO_STATUS_ISSUES_REPLY
        else
          9
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

  def get_state_icons_fe
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
=begin
    @c = 0
    @sa = News.all(:conditions => "created_on = #{Date.today}")
    puts ">>>>>>>>>>>>>>> >>>>>>>>>>>>>>> " + @sa.count.to_s
   @c = @sa.count.to_s
     puts ">>>>>>>>>>>>>>> >>>>>>>>>>>>>>> " + @c.to_s

=end
    if user.nil?
      'Utente non identificato '
    else
      s = 'QUESITO[n°' + DateTime.now.strftime("%y%m%d") + '] UTENTE[n°'
      s += user.id.to_s + '] '
      s += user.firstname? ? (user.firstname.to_s + " ") : ''
      s += user.lastname? ? user.lastname.to_s : ''
      return s
    end
  end


  def visible?(user=User.current)
    !user.nil? && user.allowed_to?(:view_news, project)
  end

  def is_quesito?
    !self.project.nil? && self.project.identifier == FeeConst::QUESITO_KEY
  end

  def set_satus(limit)
    #se il campo reply è valorizzatto allora forziamo lo status
    if self.reply && self.reply != ''
      self.status_id = FeeConst::QUESITO_STATUS_FAST_REPLY
    else
      if (self.issues && (self.issues.count > limit))
        self.status_id = FeeConst::QUESITO_STATUS_ISSUES_REPLY
      else
        self.status_id = FeeConst::QUESITO_STATUS_WAIT
      end
    end
    self.save
  end

  def is_wait_reply?
    self.status_id == FeeConst::QUESITO_STATUS_WAIT
  end

  def is_fast_reply?
    self.status_id == FeeConst::QUESITO_STATUS_FAST_REPLY #&& self.reply != ''
  end

  def is_issue_reply?
    self.status_id == FeeConst::QUESITO_STATUS_ISSUES_REPLY
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

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

require "digest/sha1"

class User < Principal
  include Redmine::SafeAttributes
  include ActionView::Helpers::DateHelper
  #include FeesHelper  #Kappao cyclic include detected
  include FeeConst
  include ApplicationHelper #getdate

  # Account statuses
  STATUS_ANONYMOUS = 0
  STATUS_ACTIVE = 1
  STATUS_REGISTERED = 2
  STATUS_LOCKED = 3

  # Different ways of displaying/sorting users
  USER_FORMATS = {
      :firstname_lastname => {:string => '#{firstname} #{lastname}', :order => %w(firstname lastname id)},
      :firstname => {:string => '#{firstname}', :order => %w(firstname id)},
      :lastname_firstname => {:string => '#{lastname} #{firstname}', :order => %w(lastname firstname id)},
      :lastname_coma_firstname => {:string => '#{lastname}, #{firstname}', :order => %w(lastname firstname id)},
      :username => {:string => '#{login}', :order => %w(login id)},
  }
  MAIL_NOTIFICATION_OPTIONS = [
      ['all', :label_user_mail_option_all],
      ['selected', :label_user_mail_option_selected],
      ['only_my_events', :label_user_mail_option_only_my_events],
      ['only_assigned', :label_user_mail_option_only_assigned],
      ['only_owner', :label_user_mail_option_only_owner],
      ['none', :label_user_mail_option_none]
  ]
  has_attached_file :photo, :styles => {:l => "200x200#", :m => "80x80#", :s => "48x48#", :xs => "32x32#"},
                    :url => "users/user_:id/:style_:basename.:extension",
                    :path => "#{RAILS_ROOT}/public/images/users/user_:id/:style_:basename.:extension",
                    :default_url => "commons/:style-no_avatar.jpg"
  validates_attachment_size :photo, :less_than => 300.kilobytes
  validates_attachment_content_type :photo, :content_type => ['image/jpeg', 'image/png', 'image/gif', 'image/bmp']

  has_and_belongs_to_many :groups, :after_add => Proc.new { |user, group| group.user_added(user) },
                          :after_remove => Proc.new { |user, group| group.user_removed(user) }
  has_many :changesets, :dependent => :nullify
  has_one :preference, :dependent => :destroy, :class_name => 'UserPreference'
  has_one :rss_token, :class_name => 'Token', :conditions => "action='feeds'"
  has_one :api_token, :class_name => 'Token', :conditions => "action='api'"
  has_one :user_profile, :dependent => :destroy, :class_name => 'UserProfile'
  belongs_to :auth_source
  #domthu20120916
  belongs_to :role, :class_name => 'Role', :foreign_key => 'role_id' #, :default => FeeConst::ROLE_REGISTERED
  #domthu20120516
  belongs_to :comune, :class_name => 'Comune', :foreign_key => 'comune_id'

  #belongs_to :account, :class_name => 'Account', :foreign_key => 'account_id' (non paga ma è abilitato al servizio)
  belongs_to :convention, :class_name => 'Convention', :foreign_key => 'convention_id'
  #l'utente può essere il referente di una (o più) organismi convenzionati
  #Puo anche essere il power_user di una convention
  #has_one :reference, :class_name => 'Convention', :dependent => :nullify
  has_many :references, :class_name => 'Convention', :dependent => :nullify

  #l'utente può essere affiliato
  belongs_to :cross_organization, :class_name => 'CrossOrganization', :foreign_key => 'cross_organization_id'
  #2.7 Choosing Between belongs_to and has_one. La foreign key si trova sulla tabella che fa belongs_to
  has_many :invoices, :class_name => 'Invoice', :dependent => :destroy
  #invvi emails
  has_many :newsletter_users, :dependent => :destroy

  acts_as_customizable

  attr_accessor :password, :password_confirmation
  attr_accessor :last_before_login_on
  # Prevents unauthorized assignments
  attr_protected :login, :admin, :password, :password_confirmation, :hashed_password

  validates_presence_of :login, :firstname, :lastname, :mail, :comune_id, :if => Proc.new { |user| !user.is_a?(AnonymousUser) }
  validates_uniqueness_of :login, :if => Proc.new { |user| !user.login.blank? }, :case_sensitive => false
  validates_uniqueness_of :mail, :if => Proc.new { |user| !user.mail.blank? }, :case_sensitive => false
  # Login must contain lettres, numbers, underscores only
  validates_format_of :login, :with => /^[a-z0-9_\-@\.]*$/i
  validates_length_of :login, :maximum => 30
  validates_length_of :firstname, :lastname, :maximum => 30
  validates_format_of :mail, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i, :allow_blank => true
  validates_length_of :mail, :maximum => 60, :allow_nil => true
  validates_confirmation_of :password, :allow_nil => true
  validates_inclusion_of :mail_notification, :in => MAIL_NOTIFICATION_OPTIONS.collect(&:first), :allow_blank => true
  validate :validate_password_length

  validates_inclusion_of :se_privacy, :in => [true], :message => "Devi accettare le condizioni"
  validates_inclusion_of :se_condition, :message => "Devi dare il tuo consenso", :in => [true] #, false]

  before_create :set_mail_notification
  before_save :update_hashed_password
  before_destroy :remove_references_before_destroy
  #--------------------- NAMED SCOPES --------------
  named_scope :in_group, lambda { |group|
    group_id = group.is_a?(Group) ? group.id : group.to_i
    {:conditions => ["#{User.table_name}.id IN (SELECT gu.user_id FROM #{table_name_prefix}groups_users#{table_name_suffix} gu WHERE gu.group_id = ?)", group_id]}
  }
  named_scope :not_in_group, lambda { |group|
    group_id = group.is_a?(Group) ? group.id : group.to_i
    {:conditions => ["#{User.table_name}.id NOT IN (SELECT gu.user_id FROM #{table_name_prefix}groups_users#{table_name_suffix} gu WHERE gu.group_id = ?)", group_id]}
  }
  #ricerca utente apartenente ad un gruppo
  named_scope :in_role, lambda { |role|
    role_id = role.is_a?(Role) ? role.id : role.to_i
    {:conditions => ["#{User.table_name}.role_id = ?", role_id]}
  }
  scope :logged, :conditions => "#{User.table_name}.status <> #{STATUS_ANONYMOUS}"
  #  scope :status, lambda {|arg| arg.blank? ? {} : {:conditions => {:status => arg.to_i}} }
  # Active non-anonymous users scope
  named_scope :active, :conditions => "#{User.table_name}.status = #{STATUS_ACTIVE}"
  # users manager  e redattori in chi-siamo
  named_scope :users_profiles_all, :include => :user_profile,
              :conditions => "#{User.table_name}.role_id = #{FeeConst::ROLE_MANAGER} OR #{User.table_name}.role_id = #{FeeConst::ROLE_AUTHOR}"
  named_scope :who_without_profile, :conditions => "(#{User.table_name}.id NOT IN (SELECT user_profiles.user_id as id from user_profiles))"
  #-----------------------------------------------


  def my_avatar(taglia, other_css='')

    head = ''
    head = '<div class="' + other_css + ' fs-my-avatar-' + taglia.to_s + '"> ' if other_css != "no-div"
    foot = ''
    foot = '</div>' if other_css != "no-div"
    if self.user_profile.nil?
      if self.use_gravatar
        head + '<img class="gravatar" src="' + my_gravatar_url(self.mail.downcase, taglia) + '" alt="mio-avatar">' + foot
      else
        case taglia
          when :l
            head + '<img class="gravatar" src="/images/' + self.photo.url(:l) + '" alt="mio-avatar">' + foot
          when :m
            head + '<img class="gravatar" src="/images/' + self.photo.url(:m) + '" alt="mio-avatar">' + foot
          when :s
            head + '<img class="gravatar" src="/images/' + self.photo.url(:s) + '" alt="mio-avatar">' + foot
          when :xs
            head + '<img class="gravatar" src="/images/' + self.photo.url(:xs) + '" alt="mio-avatar">' + foot
          else
            head + '<img class="gravatar" src="/images/commons/' + taglia.to_s + '-no_avatar.jpg" alt="mio-avatar">' + foot
        end
      end
    else
      if self.user_profile.use_gravatar
        head + '<img class="gravatar" src="' + my_gravatar_url(self.mail.downcase, taglia) + '" alt="mio-avatar">' + foot
      else
        case taglia
          when :l
            head + '<img class="gravatar" src="/images/' + self.user_profile.photo.url(:l) + '" alt="mio-avatar">' + foot
          when :m
            head + '<img class="gravatar" src="/images/' + self.user_profile.photo.url(:m) + '" alt="mio-avatar">' + foot
          when :s
            head + '<img class="gravatar" src="/images/' + self.user_profile.photo.url(:s) + '" alt="mio-avatar">' + foot
          when :xs
            head + '<img class="gravatar" src="/images/' + self.user_profile.photo.url(:xs) + '" alt="mio-avatar">' + foot
          else
            head + '<img class="gravatar" src="/images/commons/' + taglia.to_s + '-no_avatar.jpg" alt="mio-avatar">' + foot
        end

      end
    end
  end

  def my_gravatar_url(user, taglia)
    gravatar_id = Digest::MD5.hexdigest(user)
    case taglia
      when :l
        default_url = "#{RAILS_ROOT}images/commons/" + taglia.to_s + "-no_avatar.jpg"
        "http://gravatar.com/avatar/#{gravatar_id.to_s}.png?s=120{CGI.escape(#{default_url})}"
      when :m
        default_url = "#{RAILS_ROOT}images/commons/" + taglia.to_s + "-no_avatar.jpg"
        "http://gravatar.com/avatar/#{gravatar_id.to_s}.png?s=80{CGI.escape(#{default_url})}"
      when :s
        default_url = "#{RAILS_ROOT}images/commons/" + taglia.to_s + "-no_avatar.jpg"
        "http://gravatar.com/avatar/#{gravatar_id.to_s}.png?s=50{CGI.escape(#{default_url})}"
      when :xs
        default_url = "#{RAILS_ROOT}images/commons/" + taglia.to_s + "-no_avatar.jpg"
        "http://gravatar.com/avatar/#{gravatar_id.to_s}.png?s=32{CGI.escape(#{default_url})}"
      else
        '<div class="' + other_css + '" fs-my-avatar-' + taglia.to_s + '"> <img src="/images/commons/' + taglia.to_s + '-no_avatar.jpg" alt="mio-avatar"></div>'
    end
  end

  def my_quesiti
    News.all(:conditions => ['author_id = ?', self.id], :order => "created_on DESC")
  end

  def state
    str = ''
    #Control user status
    if self.locked?
     str += "<br />Utente bloccato. Contattare l'amministratore o acquistare abbonamento"
#     if self.last_login_on
#        str += "<br />Inattivo da " + distance_of_date_in_words(Time.now, self.last_login_on)
#     end
    end
    if !self.active?
     str += "<br />Utente non attivo"
    end
    #PUBLIC INSTALLATION con uso gestione abbonamento
    if Setting.fee?

      #Control Always Undesired User RoleId
      if self.isarchivied?
        str += Setting.webmsg_isarchivied
      # str += "<br />Abbonamento non valido da " + distance_of_date_in_words(Time.now, self.scadenza)
      end
      if self.isexpired?
        str += Setting.webmsg_isexpired
       # str += "<br />Abbonamento scaduto da " + distance_of_date_in_words(Time.now, self.scadenza)
      end
      if self.isrenewing?
        str += Setting.webmsg_isrenewing
      #  str += "<br />Scadenza abbonamento prossima! tra " + distance_of_date_in_words(Time.now, self.scadenza)
      #  str += "<br />Rinnovare l'abbonamento."
      end
      if self.isregistered?
        str += Setting.webmsg_isregistered
       # str += "<br />Abbonamento valido ancora per " + distance_of_date_in_words(self.scadenza, Time.now)
       # str += "<br />periodo di prova."
      end
    end
    if str.include? '@@distance_of_date_in_words@@'
      if !self.scadenza.nil?
        str = str.gsub('@@distance_of_date_in_words@@', distance_of_date_in_words(Time.now, self.scadenza))
      else
        str = str.gsub('@@distance_of_date_in_words@@', '')
      end
    end
    return str
  end

  #Chiamare quando
  def control_state
    #puts "=============ruolo " + self.role_id.to_s + " ==========control_state[" + self.scadenza.to_s + "]======================="
    #puts "=============self.locked?(" + (self.locked? ? "1" : "2") + ")=====!self.active?(" + (!self.active? ? "1" : "2") + ")=====!Setting.fee?(" + (!Setting.fee? ? "1" : "2") + ")=====self.scadenza.nil?(" + (self.scadenza.nil? ? "1" : "2") + ")======================="
    if self.locked? || !self.active? || !Setting.fee? || self.scadenza.nil?
      #puts "=============exit"
      return
    end
      #controllo della scadenza
      role_atteso = nil
      if self.admin? || self.ismanager?
        role_atteso = FeeConst::ROLE_MANAGER
        #self.datascadenza = nil # Volendo

      elsif self.isauthor?
        role_atteso = FeeConst::ROLE_AUTHOR
        #self.datascadenza = nil # Volendo

      elsif self.isvip?
        role_atteso = FeeConst::ROLE_VIP
        #self.datascadenza = nil # Volendo

      elsif self.isarchivied?
        #non fare niente. Lui esce solo attraverso cambio ruolo dalla pagina utente

      elsif self.isabbonato? || self.isrenewing? || self.isregistered? || self.isexpired?
        tipo = "renew"
        #puts "control_state " + today.to_s
        today = Date.today
        #puts "=============ruolo " + self.role_id.to_s + " ==========control_state[" + today.to_s + "/" + self.scadenza.to_s + "]==(" + (today > self.scadenza).to_s + ")====================="
        if (today > self.scadenza)
          #scaduto
          role_atteso = FeeConst::ROLE_EXPIRED
          #tipo = "proposal"
          tipo = "renew"
        else
          renew_deadline = self.scadenza - Setting.renew_days.to_i.days
          if (today > renew_deadline)
            #sta per scadere
            role_atteso = FeeConst::ROLE_RENEW
            tipo = "renew"
          else
            #tutto ok
            role_atteso = FeeConst::ROLE_ABBONATO
            tipo = "asso"
          end
        end
    else
        #puts "=============Non è soggeto a controllo "
    end
    if !role_atteso.nil? && self.role_id != role_atteso
      self.role_id = role_atteso
      if self.save!
        begin
          if tipo == "renew"
            tmail = Mailer.deliver_fee(self, tipo, Setting.template_fee_renew)
          elsif tipo == "asso"
            tmail = Mailer.deliver_fee(self, tipo, Setting.template_fee_register_asso)
          elsif tipo == "proposal"
            tmail = Mailer.deliver_fee(self, tipo, Setting.template_fee_proposal)
          else
            #tmail = Mailer.deliver_fee(self, tipo, Setting.template_fee_renew)
          end
        rescue Exception => e
          #" <span style='color: red;'>" + l(:notice_email_error, e.message) + "</span>"
        end
      end
    end
  end
#  # ruolo elaborato in funzione dello stato della scadenza

  def hide_name
    str = " utente Fiscosport n° " + self.id.to_s
    if self.comune_id && self.comune
      str += " - prov. di " + self.comune.province.name + " (" + self.comune.province.sigla + ")" unless self.comune.province.nil?
    end
    return (str.nil? || str.blank?) ? "-" : str
  end

  def getLocalization()
    str = ""
    str += self.indirizzo + "<br />" unless self.indirizzo.blank?
    if self.comune_id && self.comune
      str += self.comune.cap + " " unless !self.comune.cap
      str += self.comune.name
      str += "<br />" + self.comune.province.name + " (" + self.comune.province.sigla + ")" unless self.comune.province.nil?
      str += "<br />" + self.comune.province.region.name unless self.comune.province.region.nil?
    end
    return (str.nil? || str.blank?) ? "-" : str
  end

  def pubblicita()
    if self.privato?
      nil
    else
      CrossGroup.find(:all, :include => :group_banner, :conditions => ["se_visibile = 1 AND convention_id = #{self.convention_id}"])
    end
  end

  def privato?
    if self.convention_id && self.convention.nil?
      #verificare che non è stato eliminato la convention
      #if Convention.where(:user_id => current_user.id).blank?
      if Convention.exists?(self.convention_id)
        self.convention = Convention.find_by_id(self.convention_id)
      else
        self.convention_id = nil
        self.save!
      end
    end
    return self.convention_id.nil?
  end

  #CALL this procedure from Frontend only
  #questa funzione ritorna
  #  FALSE se l'utente non ha diritto di accedere ai contenuti
  #     basandosi sullo stato Redmine User
  #     basandosi sulla gestione abbonanemto
  #     basandosi sullo stato dell'articolo
  #  TRUE se tutto ok
  def canread?(issue = nil)
    #Control Always Undesired User RoleId
    if self.isarchivied?
      return false
    end

    #return false
    #Control issue status
    if issue && !issue.se_protetto
      return true
    end

    #Control fismine user status
    if self.locked?
      return false
    end
    if self.registered?
      #USER Must be confirmed by administrator
      return false
    end
    if !self.active?
      return false
    end

    #PUBLIC INSTALLATION
    if !Setting.fee?
      return true #PUBLIC AREA
    end

    #Control Always abilitated User RoleId
    if self.ismanager? || self.isauthor? || self.isvip?
      return true
    end

    #Control Always Undesired User RoleId
    if self.isexpired?
      return false
    end

    #Control content if public
    if issue && !issue.se_visible_web?
      # --> kappao flash[:notice] = "Articolo ancora non in linea. A breve verrà reso disponibile."
      return false
    end

    #control fee state
    self.control_state

    if self.isabbonato?
      return true
    end
    if self.isrenewing?
      return true
    end
    if self.isregistered?
      #periodo di prova non accede ai contenuti rossi
      return false
    end
  end

  def icon()
    str = ""
    if self.admin?
      str += " icon-admin"
    elsif self.ismanager?
      str += " icon-man"
    elsif self.isauthor?
      str += " icon-auth"
    elsif self.isvip?
      str += " icon-vip"
    elsif self.isabbonato?
      str += " icon-abbo"
    elsif self.isregistered?
      str += " icon-reg"
    elsif self.isrenewing?
      str += " icon-renew"
    elsif self.isexpired?
      str += " icon-exp"
    elsif self.isarchivied?
      str += " icon-arc"
    else
      #str += " icon-warning icon-adjust-min"
      str += " icon-no-role"
    end
    return str
  end

  def uicon()
    str = ""
    if self.admin?
      str += "admin"
    elsif self.ismanager?
      str += "man"
    elsif self.isauthor?
      str += "auth"
    elsif self.isvip?
      str += "vip"
    elsif self.isabbonato?
      str += "abbo"
    elsif self.isregistered?
      str += "reg"
    elsif self.isrenewing?
      str += "renew"
    elsif self.isexpired?
      str += "exp"
    elsif self.isarchivied?
      str += "arc"
    else
      #str += " icon-warning icon-adjust-min"
      str += "question"
    end
    return str
  end

  def canbackend?
    #puts "self.canbackend?(" + self.role_id.to_s + ")"
    if self.admin?
      #puts "==========> canbackend  admin"
      #Rails.logger.info("redmine canbackend OK is admin #{self}")
      return true
    end
    #FEE INSTALLATION
    if Setting.fee?
      #if (FeeConst::AUTHORED_ROLES.include? self.role_id)
      if (FeeConst::CAN_BACK_END_ROLES.include? self.role_id)
        #puts "==========> canbackend  AUTHORED_ROLES(" + self.role_id.to_s + ")"
        return true
      end
      if self.ismanager?
        #puts "==========> canbackend  manager"
        #Rails.logger.info("fee canbackend OK is staff #{self}")
        return true
      end
      if self.isauthor?
        #puts "==========> canbackend  author"
        #Rails.logger.info("fee canbackend OK is staff #{self}")
        return true
      end
      #else
    end
    return false
  end


  #l'utente gesctisce almeno un Organismo convenzionato
  def is_referente?
    return (Convention.all(:conditions => {:user_id => self.id}).count > 0)
  end

  def responsable?
    return !self.references.nil?
  end

  #List of Convention the user is power user
  def responsable_of
    self.references
  end

  #Return friendly String
  def scadenza_fra
    scadeil = self.scadenza
    if scadeil.nil?
      "Nessuna data di scadenza trovata"
    else
      today = Date.today
      #renew_deadline = scadeil.ago(Setting.renew_days.to_i.days)
      renew_deadline = scadeil - Setting.renew_days.to_i.days
      if (today < renew_deadline)
        #ABBONATO
        #str << ensure_role(_usr, FeeConst::ROLE_ABBONATO, "ABBONATO", old_state)
        "valido fino al " << getdate(scadeil)
      elsif (today < self.scadenza)
        #IN_SCADENZA
        #str << ensure_role(_usr, FeeConst::ROLE_RENEW, "ABBONATO in scadenza", old_state)
        #"scade fra " << distance_of_time_in_words(scadeil.time, Time.now)
        #private method `time' called for Mon, 01 Apr 2013:Date
        "scade fra " << distance_of_date_in_words(scadeil, today)
      else
        #  FeeConst::ROLE_EXPIRED        = 6  #_usr.data_scadenza < today
        #str << ensure_role(_usr, FeeConst::ROLE_EXPIRED, "EXPIRED", old_state)
        "scaduto da " << distance_of_date_in_words(today, scadeil)
      end
    end
  end

  #Tutti utenti che dipendono di un Organismo convenzionato NON PAGANO.
  #vale la data di scadenza della convenzione
  #Altrimenti prendiamo la data di scadenza dell'utente
  def scadenza
    if Setting.fee?
      #se l'utente non fa parte di un organismo convenzionato o quella ha una scadenza non valida
      if (self.convention.nil? || self.convention.scadenza.nil? || self.convention.scadenza.year == 0)
        # Lo consideriamo un Privato. Il privato paga lui
        if !self.datascadenza.nil? && self.datascadenza.is_a?(Date)
          return self.datascadenza.to_date
        else
          return nil
        end
      else
        #Altrimenti l'utente è sotto l'umbrella di un organismo convenzionato
        #Utente non Pagante.
        #La data di scadenza è quella di convention.data_scadenza
        #Solo se ancora valida (cf modello convention.scadenza())
        conv_date = self.convention.scadenza.to_date
        if !self.datascadenza.nil? && self.datascadenza.is_a?(Date)
          #TODO verificare se è scaduta < TODAY. altrimenti riportare la data dell'utente
          if conv_date < self.datascadenza.to_date
            return self.datascadenza.to_date
          else
            return conv_date
          end
        else
          return conv_date
        end
      end
    else
      nil
    end
  end

  def affiliato?
    return self.cross_organization.nil?
  end

  def affiliato_to
    if self.cross_organization.nil?
      return ""
    else
      return self.cross_organization.name
    end
  end

  #region ROLE * USER
  def ismanager?
    self.role_id == FeeConst::ROLE_MANAGER #= 3  #Manager<br />
  end

  def isauthor?
    self.role_id == FeeConst::ROLE_AUTHOR #= 4  #Redattore  <br />
                                          #FeeConst::ROLE_COLLABORATOR   = 4  #FeeConst::ROLE_REDATTORE   autore, redattore e collaboratore   tutti uguali<br />
  end

  def isvip?
    self.role_id == FeeConst::ROLE_VIP #= 10 #Invitato Gratuito<br />
  end

  def isabbonato?
    self.role_id == FeeConst::ROLE_ABBONATO #= 6  #Abbonato user.data_scadenza > (today - Setting.renew_days)<br />
  end

  def isregistered?
    self.role_id == FeeConst::ROLE_REGISTERED #= 9  #Ospite periodo di prova durante Setting.register_days<br />
  end

  def isrenewing?
    self.role_id == FeeConst::ROLE_RENEW #= 11  #Rinnovo: periodo prima della scadenza dipende da Setting.renew_days<br />
  end

  def isexpired?
    self.role_id == FeeConst::ROLE_EXPIRED #= 7  #Scaduto: user.data_scadenza < today<br />
  end

  def isarchivied?
    self.role_id == FeeConst::ROLE_ARCHIVIED #= 8  #Ar
  end

  def isauthored?
    if Setting.fee?
      FeeConst::AUTHORED_ROLES.include? self.role_id
    else
      #No fee management. All data are public
      true
    end
  end

  #endregion ROLE * USER

  def set_mail_notification
    self.mail_notification = Setting.default_notification_option if self.mail_notification.blank?
    true
  end

  def update_hashed_password
    # update hashed_password if password was set
    if self.password && self.auth_source_id.blank?
      salt_password(password)
    end
  end

  def reload(*args)
    @name = nil
    @projects_by_role = nil
    super
  end

  def mail=(arg)
    write_attribute(:mail, arg.to_s.strip)
  end

  def identity_url=(url)
    if url.blank?
      write_attribute(:identity_url, '')
    else
      begin
        write_attribute(:identity_url, OpenIdAuthentication.normalize_identifier(url))
      rescue OpenIdAuthentication::InvalidOpenId
        # Invlaid url, don't save
      end
    end
    self.read_attribute(:identity_url)
  end

  # Returns the user that matches provided login and password, or nil
  def self.try_to_login(login, password)
    # --> kappao flash[:error] = l(:notice_account_unactive)
    # Make sure no one can sign in with an empty password
    return nil if password.to_s.empty?
    user = find_by_login(login)
    if user
      # user is already in local database
      if !user.active?
        # --> kappao flash[:error] = l(:notice_account_unactive)
        return nil
      end
      if user.auth_source
        # user has an external authentication method
        return nil unless user.auth_source.authenticate(login, password)
      else
        # authentication with local password
        return nil unless user.check_password?(password)
      end
    else
      # user is not yet registered, try to authenticate with available sources
      attrs = AuthSource.authenticate(login, password)
      if attrs
        user = new(attrs)
        user.login = login
        user.language = Setting.default_language
        if user.save
          user.reload
          logger.info("User '#{user.login}' created from external auth source: #{user.auth_source.type} - #{user.auth_source.name}") if logger && user.auth_source
        end
      end
    end
    user.update_attribute(:last_login_on, Time.now) if user && !user.new_record?
    user
  rescue => text
    raise text
  end

  # Returns the user who matches the given autologin +key+ or nil
  def self.try_to_autologin(key)
    tokens = Token.find_all_by_action_and_value('autologin', key)
    # Make sure there's only 1 token that matches the key
    if tokens.size == 1
      token = tokens.first
      if (token.created_on > Setting.autologin.to_i.day.ago) && token.user && token.user.active?
        token.user.update_attribute(:last_login_on, Time.now)
        token.user
      end
    end
  end

  def self.name_formatter(formatter = nil)
    USER_FORMATS[formatter || Setting.user_format] || USER_FORMATS[:firstname_lastname]
  end

  # Returns an array of fields names than can be used to make an order statement for users
  # according to how user names are displayed
  # Examples:
  #
  #   User.fields_for_order_statement              => ['users.login', 'users.id']
  #   User.fields_for_order_statement('authors')   => ['authors.login', 'authors.id']
  def self.fields_for_order_statement(table=nil)
    table ||= table_name
    name_formatter[:order].map { |field| "#{table}.#{field}" }
  end

  # Return user's full name for display
  def name(formatter = nil)
    f = self.class.name_formatter(formatter)
    if formatter
      eval('"' + f[:string] + '"')
    else
      @name ||= eval('"' + f[:string] + '"')
    end
  end

  def active?
    self.status == STATUS_ACTIVE
  end

  def registered?
    self.status == STATUS_REGISTERED
  end

  def locked?
    self.status == STATUS_LOCKED
  end

  def activate
    self.status = STATUS_ACTIVE
  end

  def register
    self.status = STATUS_REGISTERED
  end

  def lock
    self.status = STATUS_LOCKED
  end

  def activate!
    update_attribute(:status, STATUS_ACTIVE)
  end

  def register!
    update_attribute(:status, STATUS_REGISTERED)
  end

  def lock!
    update_attribute(:status, STATUS_LOCKED)
  end

  # Returns true if +clear_password+ is the correct user's password, otherwise false
  def check_password?(clear_password)
    if auth_source_id.present?
      auth_source.authenticate(self.login, clear_password)
    else
      #puts '**********************try_to_login by check_password hash_password(' + clear_password + ', ' + hashed_password + ')********************'
      User.hash_password("#{salt}#{User.hash_password clear_password}") == hashed_password
    end
  end

  # Generates a random salt and computes hashed_password for +clear_password+
  # The hashed password is stored in the following form: SHA1(salt + SHA1(password))
  def salt_password(clear_password)
    self.salt = User.generate_salt
    self.hashed_password = User.hash_password("#{salt}#{User.hash_password clear_password}")
  end

  # Does the backend storage allow this user to change their password?
  def change_password_allowed?
    return true if auth_source_id.blank?
    return auth_source.allow_password_changes?
  end

  # Generate and set a random password.  Useful for automated user creation
  # Based on Token#generate_token_value
  #
  def random_password
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    password = ''
    #40.times { |i| password << chars[rand(chars.size-1)] }
    15.times { |i| password << chars[rand(chars.size-1)] }
    self.password = password
    self.password_confirmation = password
    self.pwd = password
    self
  end

  def pref
    self.preference ||= UserPreference.new(:user => self)
  end

  def time_zone
    @time_zone ||= (self.pref.time_zone.blank? ? nil : ActiveSupport::TimeZone[self.pref.time_zone])
  end

  def wants_comments_in_reverse_order?
    self.pref[:comments_sorting] == 'desc'
  end

  # Return user's RSS key (a 40 chars long string), used to access feeds
  def rss_key
    token = self.rss_token || Token.create(:user => self, :action => 'feeds')
    token.value
  end

  # Return user's API key (a 40 chars long string), used to access the API
  def api_key
    token = self.api_token || self.create_api_token(:action => 'api')
    token.value
  end

  # Return an array of project ids for which the user has explicitly turned mail notifications on
  def notified_projects_ids
    @notified_projects_ids ||= memberships.select { |m| m.mail_notification? }.collect(&:project_id)
  end

  def notified_project_ids=(ids)
    Member.update_all("mail_notification = #{connection.quoted_false}", ['user_id = ?', id])
    Member.update_all("mail_notification = #{connection.quoted_true}", ['user_id = ? AND project_id IN (?)', id, ids]) if ids && !ids.empty?
    @notified_projects_ids = nil
    notified_projects_ids
  end

  def valid_notification_options
    self.class.valid_notification_options(self)
  end

  # Only users that belong to more than 1 project can select projects for which they are notified
  def self.valid_notification_options(user=nil)
    # Note that @user.membership.size would fail since AR ignores
    # :include association option when doing a count
    if user.nil? || user.memberships.length < 1
      MAIL_NOTIFICATION_OPTIONS.reject { |option| option.first == 'selected' }
    else
      MAIL_NOTIFICATION_OPTIONS
    end
  end

  # Find a user account by matching the exact login and then a case-insensitive
  # version.  Exact matches will be given priority.
  def self.find_by_login(login)
    # force string comparison to be case sensitive on MySQL
    type_cast = (ActiveRecord::Base.connection.adapter_name == 'MySQL') ? 'BINARY' : ''

    # First look for an exact match
    user = first(:conditions => ["#{type_cast} login = ?", login])
    # Fail over to case-insensitive if none was found
    user ||= first(:conditions => ["#{type_cast} LOWER(login) = ?", login.to_s.downcase])
  end

  def self.find_by_rss_key(key)
    token = Token.find_by_value(key)
    token && token.user.active? ? token.user : nil
  end

  def self.find_by_api_key(key)
    token = Token.find_by_action_and_value('api', key)
    token && token.user.active? ? token.user : nil
  end

  # Makes find_by_mail case-insensitive
  def self.find_by_mail(mail)
    find(:first, :conditions => ["LOWER(mail) = ?", mail.to_s.downcase])
  end

  # Returns true if the default admin account can no longer be used
  def self.default_admin_account_changed?
    !User.active.find_by_login("admin").try(:check_password?, "admin")
  end

  def to_s
    name
  end

  # Returns the current day according to user's time zone
  def today
    if time_zone.nil?
      Date.today
    else
      Time.now.in_time_zone(time_zone).to_date
    end
  end

  def logged?
    true
  end

  def anonymous?
    !logged?
  end

  # Return user's roles for project
  def roles_for_project(project)
    roles = []
    # No role on archived projects
    return roles unless project && project.active?
    if logged?
      # Find project membership
      membership = memberships.detect { |m| m.project_id == project.id }
      if membership
        roles = membership.roles
      else
        @role_non_member ||= Role.non_member
        roles << @role_non_member
      end
    else
      @role_anonymous ||= Role.anonymous
      roles << @role_anonymous
    end
    roles
  end

  # Return true if the user is a member of project
  def member_of?(project)
    !roles_for_project(project).detect { |role| role.member? }.nil?
  end

  # Returns a hash of user's projects grouped by roles
  def projects_by_role
    return @projects_by_role if @projects_by_role

    @projects_by_role = Hash.new { |h, k| h[k]=[] }
    memberships.each do |membership|
      membership.roles.each do |role|
        @projects_by_role[role] << membership.project if membership.project
      end
    end
    @projects_by_role.each do |role, projects|
      projects.uniq!
    end

    @projects_by_role
  end

  # Returns true if user is arg or belongs to arg
  def is_or_belongs_to?(arg)
    if arg.is_a?(User)
      self == arg
    elsif arg.is_a?(Group)
      arg.users.include?(self)
    else
      false
    end
  end

  # Return true if the user is allowed to do the specified action on a specific context
  # Action can be:
  # * a parameter-like Hash (eg. :controller => 'projects', :action => 'edit')
  # * a permission Symbol (eg. :edit_project)
  # Context can be:
  # * a project : returns true if user is allowed to do the specified action on this project
  # * an array of projects : returns true if user is allowed on every project
  # * nil with options[:global] set : check if user has at least one role allowed for this action,
  #   or falls back to Non Member / Anonymous permissions depending if the user is logged
  def allowed_to?(action, context, options={}, &block)
    if context && context.is_a?(Project)
      # No action allowed on archived projects
      return false unless context.active?
      # No action allowed on disabled modules
      return false unless context.allows_to?(action)
      # Admin users are authorized for anything else
      return true if admin?
      # Sandro -> risolve il problema che un author non puo' vedere le edizioni
      return true if  User.current.isauthor?
      return true if User.current.ismanager?
      # fine  sandro
      roles = roles_for_project(context)
      return false unless roles
      roles.detect { |role|
        (context.is_public? || role.member?) &&
            role.allowed_to?(action) &&
            (block_given? ? yield(role, self) : true)
      }
    elsif context && context.is_a?(Array)
      # Authorize if user is authorized on every element of the array
      context.map do |project|
        allowed_to?(action, project, options, &block)
      end.inject do |memo, allowed|
        memo && allowed
      end
    elsif options[:global]
      # Admin users are always authorized
      return true if admin?

      # authorize if user has at least one role that has this permission
      roles = memberships.collect { |m| m.roles }.flatten.uniq
      roles << (self.logged? ? Role.non_member : Role.anonymous)
      roles.detect { |role|
        role.allowed_to?(action) &&
            (block_given? ? yield(role, self) : true)
      }
    else
      false
    end
  end

  # Is the user allowed to do the specified action on any project?
  # See allowed_to? for the actions and valid options.
  def allowed_to_globally?(action, options, &block)
    allowed_to?(action, nil, options.reverse_merge(:global => true), &block)
  end

  safe_attributes 'login',
                  'firstname',
                  'lastname',
                  'mail',
                  'mail_notification',
                  'language',
                  'custom_field_values',
                  'custom_fields',
                  'identity_url',
                  'codice',
                  'pwd',
                  'login_fisco',
                  'mail_fisco',
                  'nome',
                  'titolo',
                  'soc',
                  'parent',
                  'note',
                  'indirizzo',
                  'cap',
                  'comune_id',
                  'prov',
                  'sede',
                  'telefono',
                  'fax',
                  'telefono2',
                  'mail2',
                  'codice_attivazione',
                  'iva',
                  'codicefiscale',
                  'num_reg_coni',
                  'se_condition',
                  'use_gravatar',
                  'photo',
                  'se_privacy'


  safe_attributes 'status',
                  'auth_source_id',
                  'data',
                  'datascadenza',
                  'convention_id',
                  'role_id',
                  'cross_organization_id',
                  'tariffa_precedente',
                  'power_user',
                  'conferma_registrazione',
                  'disabilitato',
                  'iva_precedente',
                  'pagamento_precedente',
                  'data_ultimo_pagamento',
                  'data_accredito',
                  'anno_competenza',
                  'crediti',
                  'annotazioni',
                  :if => lambda { |user, current_user| current_user.admin? }

  safe_attributes 'group_ids',
                  :if => lambda { |user, current_user| current_user.admin? && !user.new_record? }

  # Utility method to help check if a user should be notified about an
  # event.
  #
  # TODO: only supports Issue events currently
  def notify_about?(object)
    case mail_notification
      when 'all'
        true
      when 'selected'
        # user receives notifications for created/assigned issues on unselected projects
        if object.is_a?(Issue) && (object.author == self || is_or_belongs_to?(object.assigned_to))
          true
        else
          false
        end
      when 'none'
        false
      when 'only_my_events'
        if object.is_a?(Issue) && (object.author == self || is_or_belongs_to?(object.assigned_to))
          true
        else
          false
        end
      when 'only_assigned'
        if object.is_a?(Issue) && is_or_belongs_to?(object.assigned_to)
          true
        else
          false
        end
      when 'only_owner'
        if object.is_a?(Issue) && object.author == self
          true
        else
          false
        end
      else
        false
    end
  end

  def self.current=(user)
    @current_user = user
  end

  def self.current
    @current_user ||= User.anonymous
  end

  # Returns the anonymous user.  If the anonymous user does not exist, it is created.  There can be only
  # one anonymous user per database.
  def self.anonymous
    anonymous_user = AnonymousUser.find(:first)
    if anonymous_user.nil?
      anonymous_user = AnonymousUser.create(:lastname => 'Anonymous', :firstname => '', :mail => '', :login => '', :status => 0)
      raise 'Unable to create the anonymous user.' if anonymous_user.new_record?
    end
    anonymous_user
  end

  # Salts all existing unsalted passwords
  # It changes password storage scheme from SHA1(password) to SHA1(salt + SHA1(password))
  # This method is used in the SaltPasswords migration and is to be kept as is
  def self.salt_unsalted_passwords!
    transaction do
      User.find_each(:conditions => "salt IS NULL OR salt = ''") do |user|
        next if user.hashed_password.blank?
        salt = User.generate_salt
        hashed_password = User.hash_password("#{salt}#{user.hashed_password}")
        User.update_all("salt = '#{salt}', hashed_password = '#{hashed_password}'", ["id = ?", user.id])
      end
    end
  end

  protected

  def validate_password_length
    # Password length validation based on setting
    if !password.nil? && password.size < Setting.password_min_length.to_i
      errors.add(:password, :too_short, :count => Setting.password_min_length.to_i)
    end
  end

  private

  # Removes references that are not handled by associations
  # Things that are not deleted are reassociated with the anonymous user
  def remove_references_before_destroy
    return if self.id.nil?

    substitute = User.anonymous
    Attachment.update_all ['author_id = ?', substitute.id], ['author_id = ?', id]
    Comment.update_all ['author_id = ?', substitute.id], ['author_id = ?', id]
    Issue.update_all ['author_id = ?', substitute.id], ['author_id = ?', id]
    Issue.update_all 'assigned_to_id = NULL', ['assigned_to_id = ?', id]
    Journal.update_all ['user_id = ?', substitute.id], ['user_id = ?', id]
    JournalDetail.update_all ['old_value = ?', substitute.id.to_s], ["property = 'attr' AND prop_key = 'assigned_to_id' AND old_value = ?", id.to_s]
    JournalDetail.update_all ['value = ?', substitute.id.to_s], ["property = 'attr' AND prop_key = 'assigned_to_id' AND value = ?", id.to_s]
    Message.update_all ['author_id = ?', substitute.id], ['author_id = ?', id]
    News.update_all ['author_id = ?', substitute.id], ['author_id = ?', id]
    # Remove private queries and keep public ones
    Query.delete_all ['user_id = ? AND is_public = ?', id, false]
    Query.update_all ['user_id = ?', substitute.id], ['user_id = ?', id]
    TimeEntry.update_all ['user_id = ?', substitute.id], ['user_id = ?', id]
    Token.delete_all ['user_id = ?', id]
    Watcher.delete_all ['user_id = ?', id]
    WikiContent.update_all ['author_id = ?', substitute.id], ['author_id = ?', id]
    WikiContent::Version.update_all ['author_id = ?', substitute.id], ['author_id = ?', id]
  end

  # Return password digest
  def self.hash_password(clear_password)
    Digest::SHA1.hexdigest(clear_password || "")
  end

  # Returns a 128bits random salt as a hex string (32 chars long)
  def self.generate_salt
    ActiveSupport::SecureRandom.hex(16)
  end

end

class AnonymousUser < User

  def validate_on_create
    # There should be only one AnonymousUser in the database
    errors.add :base, 'An anonymous user already exists.' if AnonymousUser.find(:first)
  end

  def available_custom_fields
    []
  end

  # Overrides a few properties
  def logged?;
    false
  end

  def admin;
    false
  end

  def name(*args)
    ; I18n.t(:label_user_anonymous)
  end

  def mail;
    nil
  end

  def time_zone;
    nil
  end

  def rss_key;
    nil
  end

  # Anonymous user can not be destroyed
  def destroy
    false
  end
end

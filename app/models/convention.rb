class Convention < ActiveRecord::Base
  has_attached_file :image, :styles => {:l => "200x200#", :m => "80x80#", :s => "48x48#", :xs => "32x32#"},
                    :url => "commons/assos/:id:style.:extension",
                    :path => "#{RAILS_ROOT}/public/images/commons/assos/:id:style.:extension",
                    :default_style => :l,
                    :default_url => "commons/:style_ico-no-image.jpg"
  validates_attachment_size :image, :less_than => 200.kilobytes
  validates_attachment_content_type :image, :content_type => ['image/jpeg', 'image/png', 'image/gif', 'image/bmp']

  include ApplicationHelper #get_short_date
  include FeesHelper #ROLE_XXX  gedate

  #domthu20120516 #Non eliminare utenti ma solo togliere il riferimento alla convention_id
  has_many :users, :dependent => :nullify
  #counter_cahe include field users_count in convention, :counter_cache => true
  #http://stackoverflow.com/questions/9400687/can-a-counter-cache-be-used-with-a-has-many
  belongs_to :comune, :class_name => 'Comune', :foreign_key => 'comune_id' #, :default => null
  belongs_to :user #, :class_name => 'User', :foreign_key => 'user_id'#, :default => null
  has_many :invoices, :class_name => 'Invoice', :dependent => :destroy
  #Con questi 3 campi siamo in grado di definire quale organismo con quale copertura geografica
  belongs_to :cross_organization, :class_name => 'CrossOrganization', :foreign_key => 'cross_organization_id'
  belongs_to :region, :class_name => 'Region', :foreign_key => 'region_id' #, :default => null
  belongs_to :province, :class_name => 'Province', :foreign_key => 'province_id' #, :default => null
  has_one :group_banner, :dependent => :destroy, :class_name => 'GroupBanner'
  named_scope :conventions_all_logos, :conditions => "#{Convention.table_name}.logo_in_fe = #{true} AND #{Convention.table_name}.image_file_name IS NOT NULL"
  #string
  validates_presence_of :ragione_sociale
  validates_uniqueness_of :ragione_sociale, :case_sensitive => false
  validates_length_of :ragione_sociale, :maximum => 255
  validates_presence_of :email
  validates_uniqueness_of :email, :case_sensitive => false
  validates_length_of :email, :maximum => 100, :allow_nil => true
  #  validates_uniqueness_of :mail, :if => Proc.new { |user| !user.mail.blank? }, :case_sensitive => false
  validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i, :allow_blank => true
  validates_length_of :indirizzo, :maximum => 255
  validates_length_of :email_alt, :maximum => 100, :allow_nil => true
  #  validates_uniqueness_of :mail, :if => Proc.new { |user| !user.mail.blank? }, :case_sensitive => false
  validates_format_of :email_alt, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i, :allow_blank => true
  #text-area? CSS? HTML area
  validates_length_of :comunicazioni, :maximum => 4000

#  def asso_symbols
#    [asso.to_sym]
#  end

  def to_s
    str = ""
    #str = "[" << self.id.to_s << "] "
    str = "[" + (self.users.any? ? self.users.count.to_s : "0") + "]  " #<i class='icon'></i>"
    str << (self.ragione_sociale.blank? ? "?" : self.ragione_sociale)
    str << (self.presidente.blank? ? "" : " (" + self.presidente + ")")
    return str

  end

  alias :name :to_s

  def name_with_users_count
    str = ""
    str = "[" + self.users_count.to_s + "]  "
    str << (self.cross_organization.nil? ? "" : self.cross_organization.name + " ")
    str << (self.ragione_sociale.blank? ? "?" : self.ragione_sociale)
    return str
  end

  def index()
    str = ""
    #str = "[" << self.id.to_s << "] "
    str = '<div class="count">' + (self.users.any? ? self.users.count.to_s : "0") + ' </div><strong> '
    str << (self.ragione_sociale.blank? ? "?" : self.ragione_sociale)+'</strong><br /><span style="color:#484848">'
    str << (self.presidente.blank? ? "" : " presidente: " + self.presidente + "</span>")
    return str

  end

#nome del patto: Federazione con copertura geografica
  def pact
    str = ""
    #str = "[" << self.id.to_s << "] "
    str << (self.cross_organization.nil? ? "" : self.cross_organization.name)
    str << " - " + get_zone
    str << " - " + get_short_date(self.data_scadenza)
    return str
  end

  def get_zone
    str = ""
    if self.province.nil? #iniziare dalla provincia
      if self.region.nil?
        str << " Nazionale"
      else
        str << "Regionale (" + self.region.name + ")"
      end
    else
      str << " Provinciale (" + self.province.name + ")"
    end
    return str
  end

  #Tutti utenti che dipendono di un Associazione == Organization
  #NON PAGANO. vale la data di scadenza dell'associazione
  def havePowerUser?
    #!self.user.nil? && self.user.power_user
    self.user && self.user.power_user
  end

  def scadenza
    return (self.data_scadenza.nil? || self.data_scadenza.blank?) ? nil : self.data_scadenza.to_date
  end

  def se_sport?
    self.cross_organization.type_organization.type_sport
  end

  # ruolo elaborato in funzione dello stato della scadenza
  def role_id
    if self.data_scadenza.nil?
      return FeeConst::ROLE_ARCHIVIED
    end
    today = Date.today
    if (today > self.scadenza)
      return FeeConst::ROLE_EXPIRED
    else
      renew_deadline = self.scadenza - Setting.renew_days.to_i.days
      if (today > renew_deadline)
        return FeeConst::ROLE_RENEW
      else
        return FeeConst::ROLE_ABBONATO
      end
    end
    return FeeConst::ROLE_ARCHIVIED
  end

  def user_icon()
    if self.user
      self.user.icon()
    else #default
         #' icon-warning icon-adjust-min'
      ' icon-no-user'
    end
  end

  def soci
    User.all(:conditions => {:convention_id => self.id})
  end

  #Chiamare quando
  def control_state
    puts "=============ruolo " + self.role_id.to_s + " ==========control_state[" + self.scadenza.to_s + "]======================="
    if self.scadenza == nil
      return "scadenza non definita"
    end
    #controllo della scadenza
    role_atteso = nil
    today = Date.today
    if (today > self.scadenza)
      #scaduto
      role_atteso = FeeConst::ROLE_EXPIRED
      tipo = "renew"
    end

#    elsif self.isabbonato? || self.isrenewing? || self.isexpired?

#      tipo = "renew"
#      #puts "control_state " + today.to_s

#      #puts "=============ruolo " + self.role_id.to_s + " ==========control_state[" + today.to_s + "/" + self.scadenza.to_s + "]==(" + (today > self.scadenza).to_s + ")====================="
#      if (today > self.scadenza)
#        #scaduto
#        role_atteso = FeeConst::ROLE_EXPIRED
#        tipo = "renew"
#      else
#        renew_deadline = self.scadenza - Setting.renew_days.to_i.days
#        if (today > renew_deadline)
#          #sta per scadere solo per abbonato
#          role_atteso = FeeConst::ROLE_RENEW
#          tipo = "proposal"
#        else
#          #tutto ok
#          role_atteso = FeeConst::ROLE_ABBONATO
#          tipo = "asso"
#        end
#      end
#    else
#      #puts "=============Non è soggeto a controllo "
#    end
#    if !role_atteso.nil? && self.role_id != role_atteso
#      self.role_id = role_atteso
#      if self.save!
#        begin
#          if tipo == "renew"
#            #invia email solo ai paganti
#            if self.convention_id.nil?
#              tmail = Mailer.deliver_fee(self, tipo, Setting.template_fee_renew)
#            end
#          elsif tipo == "asso"
#            #tmail = Mailer.deliver_fee(self, tipo, Setting.template_fee_register_asso) Attenzione questo è il messaggio destinato al power_user per convalidare o no una persona
#          elsif tipo == "proposal"
#            #invia email solo ai paganti
#            if self.convention_id.nil?
#              tmail = Mailer.deliver_fee(self, "renew", Setting.template_fee_renew)
#            end
#            #invia email solo ai paganti
#            #if self.convention_id.nil?
#            #  tmail = Mailer.deliver_fee(self, tipo, Setting.template_fee_proposal)
#            #end
#          else
#            #invia email solo ai paganti
#            #if self.convention_id.nil?
#            #  tmail = Mailer.deliver_fee(self, tipo, Setting.template_fee_renew)
#            #end
#          end
#        rescue Exception => e
#          #" <span style='color: red;'>" + l(:notice_email_error, e.message) + "</span>"
#        end
#      end
#    end
#    @conv.soci.each do |usr|
#      # sandro rimosso il send_warning per errore di cookie
#      #send_warning(msg + "<b style='color: green;'>Tolto con per utente</b> "+ usr.name + "(" + usr.id.to_s + ") di ruolo (" + get_abbonamento_name(usr.role_id) + ")")
#      usr.convention_id = nil
#      usr.save! #--> save_without_transactions
#      usr.control_state
#    end
  end

  def getDefault4invoice()
    str = ""
    str += "<dl><dt> Spett.le </dt><dd>"
    str += "<b>" + self.ragione_sociale + " </b><br />" unless self.ragione_sociale.blank? || self.ragione_sociale.nil?
    str += self.indirizzo + "<br />" unless self.indirizzo.blank?
    if self.comune_id && self.comune
      str += self.comune.cap + " " unless !self.comune.cap
      str += self.comune.name
      str += "<br />" + self.comune.province.name + " (" + self.comune.province.sigla + ")" unless self.comune.province.nil?
    end
    str += "</dd>"
    str += "<dt> C.F. </dt><dd>" + self.codicefiscale.to_s + "</dd>" unless self.codicefiscale.blank? || self.codicefiscale.nil?
    str += "<dt> P.I. </dt><dd>" +self.partitaiva.to_s  + "</dd>"  unless self.partitaiva.blank? || self.partitaiva.nil?
    str += "</dl>"
    return str
  end
  def getDefault4invoice_contatto()
    str = ""
    str += "<dl><dt> Cod.ref. Fiscosport </dt><dd>" +  self.user_id.to_s + "</dd>"
    str += ("<dl><dt> Presidente </dt><dd>" +  self.presidente + "</dd>"  unless  self.presidente.blank? || self.presidente.nil?)
    str += ("<dl><dt> Referente </dt><dd>" +  self.referente + "</dd>" unless  self.referente.blank? || self.referente.nil?)
    str += ("<dl><dt> Email </dt><dd>" +  self.email + "</dd>" unless  self.email.blank? || self.email.nil?)
    str += "</dl>"
    return str
  end
end

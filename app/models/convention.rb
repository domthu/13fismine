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

  #domthu20120516
  has_many :users, :dependent => :nullify #Non fare niente dobbiamo eliminare convention_id
  belongs_to :comune, :class_name => 'Comune', :foreign_key => 'comune_id' #, :default => null
  #Il responsabile del patto - contratto
  #2.7 Choosing Between belongs_to and has_one
  #belongs_to :referente, :class_name => 'User', :foreign_key => 'user_id'#, :default => null
  belongs_to :user #, :class_name => 'User', :foreign_key => 'user_id'#, :default => null
  #Con questi 3 campi siamo in grado di definire quale organismo con quale copertura geografica
  belongs_to :cross_organization, :class_name => 'CrossOrganization', :foreign_key => 'cross_organization_id'
  belongs_to :region, :class_name => 'Region', :foreign_key => 'region_id' #, :default => null
  belongs_to :province, :class_name => 'Province', :foreign_key => 'province_id' #, :default => null
  has_one :group_banner, :dependent => :destroy, :class_name => 'GroupBanner'
  named_scope :conventions_all_logos
  #              :conditions => "#{Convention.table_name}.se_visibile = #{true} AND #{CrossOrganization.table_name}.image_file_name IS NOT NULL"
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
    if self.region.nil?
      if self.province.nil?
        str << " Nazionale"
      else
        str << " Provinciale (" + self.province.name + ")"
      end
    else
      str << "Regionale (" + self.region.name + ")"
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
    return self.data_scadenza
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

end

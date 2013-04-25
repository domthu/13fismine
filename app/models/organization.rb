class Organization < ActiveRecord::Base

  include ApplicationHelper #get_short_date

  #domthu20120516
  #has_many :users, :dependent => :nullify
  belongs_to :user

  belongs_to :region, :class_name => 'Region', :foreign_key => 'region_id'#, :default => null
  belongs_to :province, :class_name => 'Province', :foreign_key => 'province_id'#, :default => null
  belongs_to :comune, :class_name => 'Comune', :foreign_key => 'comune_id'#, :default => null
  #2.7 Choosing Between belongs_to and has_one
  belongs_to :referente, :class_name => 'User', :foreign_key => 'user_id'#, :default => null

  #ATTENZIONE Organization (Organismi Associati) e Asso (Categoria Utente) hanno una relazione 1 a 1
  belongs_to :asso, :class_name => 'Asso', :foreign_key => 'asso_id'

  #ATTENZIONE i 2 campi Sigla (ex Organismi) e Tipo organizzazione sono raddunati in una foreign_key
  belongs_to :cross_organization, :class_name => 'CrossOrganization', :foreign_key => 'cross_organization_id'
  #TODO: verificare ci potrebbe essere che alcuni associazione Sigla - Tipo non appare nella tabella CrossOrganization
  # idem for User


  def to_s
    str = "[" << self.id.to_s << "] "
    str << (self.cross_organization.nil?  ? "" : self.cross_organization.name)
    #str << (self.asso.nil? ? "" : " (" << self.asso.name << ") ")
    str << " - " + get_short_date(self.data_scadenza)
    str << (self.region.nil? ? "" : " - " + self.region.name)
    str << (self.province.nil? ? "" : ", " + self.province.name)
    str << (self.comune.nil? ? "" : ", " + self.comune.name)
    return str
  end

  alias :name :to_s

  def havePowerUser?
    #!self.referente.nil? && self.referente.power_user
    self.referente && self.referente.power_user
  end

  def scadenza
    return self.data_scadenza
  end

  def scadenza_format

  end

  def GetAssociati
    if self.asso_id || self.asso
      User.all(:conditions => {:asso_id => self.id})
    end
  end

end

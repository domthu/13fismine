class Invoice < ActiveRecord::Base

  belongs_to :user, :class_name => 'User', :foreign_key => 'user_id'
  belongs_to :convention, :class_name => 'Convention', :foreign_key => 'convention_id'
  belongs_to :contract_user, :class_name => 'ContractUser', :foreign_key => 'contract_user_id'
  belongs_to :payment, :class_name => 'Payment', :foreign_key => 'payment_id'

  validates_presence_of :numero_fattura, :anno, :data_fattura, :tariffa, :iva
  #validates_uniqueness_of :numero_fattura, :scope => [:numero_fattura, :anno, :data_fattura]
  #validate :numero_fattura_must_be_unique_in_anno_and_data_fattura

  #Overflow cookie?
  def numero_fattura_must_be_unique_in_anno_and_data_fattura
    #return if field.blank?
    not_uniq = self.class.count(:conditions => ["anno = ? AND numero_fattura = ? AND YEAR(data_fattura) = ?", self.anno, self.numero_fattura, self.data_fattura.year])
    if not_uniq > 0
      #self.errors.add(:data_fattura, "anno, numero_fattura e anno di data_fattura devono essere unici")
      flash[:error] = "anno, numero_fattura e anno di data_fattura devono essere unici"
    end
    #not_uniq = self.class.where(:anno=>self.anno,:numero_fattura=>self.numero_fattura).where("YEAR(data_fattura) = ?",data_fattura.year).first
    #self.errors.add(:data_fattura, "anno, numero_fattura e anno di data_fattura devono essere unici") if not_uniq
  end

  def to_s
    numero_fattura.to_s
  end

  alias :name :to_s

  def subject
    if (self.convention_id && self.convention)
      return self.convention
    end
    if (self.user_id && self.user)
      return self.user
    end
    return ""
  end

  def numero_fiscale
    numero_fattura.to_s + '/' + anno.to_s
  end

  def numero_fiscale_mail
    numero_fattura.to_s + '_' + anno.to_s
  end

  def getFilePath
    #return RAILS_ROOT + self.getFileDir
    return "#{RAILS_ROOT}" + self.getFileDir
  end

  def getFileUrl
    return "http://" + Setting.host_name + self.getFileDir
  end

  def getFileDir
    return "/files/invoices/" + self.getInvoiceFilename
  end

  def getInvoiceFilename
    s= ''
    a = '0000'
    if (self.convention_id && self.convention)
     s +="c" + self.convention_id.to_s
    end
    if (self.user_id && self.user)
     s += "u" + self.user_id.to_s
    end
    if self.anno
      a = self.anno.to_s
    end
    return   "fattura_" + a + '_' + self.numero_fattura.to_s + '_' + s + ".pdf"
  end

end

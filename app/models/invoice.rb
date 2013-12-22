class Invoice < ActiveRecord::Base

  belongs_to :user, :class_name => 'User', :foreign_key => 'user_id'
  belongs_to :convention, :class_name => 'Convention', :foreign_key => 'convention_id'
  belongs_to :contract_user, :class_name => 'ContractUser', :foreign_key => 'contract_user_id'
  belongs_to :payment, :class_name => 'Payment', :foreign_key => 'payment_id'

  validates_presence_of :numero_fattura, :anno, :data_fattura, :tariffa, :iva
  validates_uniqueness_of :numero_fattura, :scope => [:numero_fattura, :anno]

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

  def getInvoiceFilePath
    s= ''
    a = '0000'

    if (self.convention_id && self.convention)
     s +="c" + self.convention_id.to_s
    end
    if (self.user_id && self.user)
     s += "u" + self.user_id.to_s
    end
    if self.anno
      a = 'fs' + self.anno.to_s
    end

  return   "/public/images/files/fattura_" + self.id.to_s + a +  s + ".pdf"

  end

end

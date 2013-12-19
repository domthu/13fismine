class Invoice < ActiveRecord::Base

  belongs_to :user, :class_name => 'User', :foreign_key => 'user_id'
  belongs_to :convention, :class_name => 'Convention', :foreign_key => 'convention_id'
  belongs_to :contract_user, :class_name => 'ContractUser', :foreign_key => 'contract_user_id'
  belongs_to :payment, :class_name => 'Payment', :foreign_key => 'payment_id'

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

end

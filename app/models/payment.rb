class Payment < ActiveRecord::Base

  has_many :invoices, :dependent => :nullify

  def to_s
    "(" + self.abbrev + ") " + self.pagamento
  end

  alias :name :to_s

end

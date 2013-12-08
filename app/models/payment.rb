class Payment < ActiveRecord::Base
  has_many :invoice , :dependent => :nullify



  def to_s
    pagamento
  end

  alias :name :to_s
end

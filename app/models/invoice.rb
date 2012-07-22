class Invoice < ActiveRecord::Base

  #domthu20120516
  belongs_to :user, :class_name => 'User', :foreign_key => 'user_id'

  def to_s
    numero_fattura.to_s
  end

  alias :name :to_s

end

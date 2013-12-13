class ContractUser < ActiveRecord::Base

  has_many :invoices, :dependent => :nullify
  belongs_to :user
  belongs_to :contract

end

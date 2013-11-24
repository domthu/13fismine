class EmailType < ActiveRecord::Base

  has_many :newsletter_users, :dependent => :nullify
  validates_length_of :description, :maximum => 30

  def to_s
    self.description
  end

  alias :name :to_s

end

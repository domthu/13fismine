class Information < ActiveRecord::Base

  has_one :newsletter_users, :dependent => :nullify

  validates_presence_of :description

  validates_length_of :subject, :maximum => 100
  validates_length_of :description, :maximum => 1000

  def to_s
    if (subject.nil? || subject.blank?)
      truncate(self.description, :length => 100, :omission => '...')
    else
      self.subject
    end
  end

  alias :name :to_s

end

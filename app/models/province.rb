class Province < ActiveRecord::Base

  #domthu20120516
  has_many :comunes, :dependent => :destroy
  has_many :organizations, :dependent => :nullify

  belongs_to :region, :class_name => 'Region', :foreign_key => 'region_id'

  def to_s
    name + '(' + sigla + ')'
  end

  alias :name_full :to_s
  #alias :name :to_s

end

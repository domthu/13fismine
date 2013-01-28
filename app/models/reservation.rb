class Reservation < ActiveRecord::Base
  belongs_to :issue
end

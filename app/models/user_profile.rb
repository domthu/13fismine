class UserProfile < ActiveRecord::Base
  belongs_to :user
  attr_accessor :image_file_name, :image_content_type, :image_file_size, :image_updated_at
  has_attached_file :photo, :styles => {:medium => "175x175>"},
                    :url => "/assets/products/:id/:style/:basename.:extension",
                    :path => ":rails_root/public/images/users/profiles/:id/:style/:basename.:extension"
  has_attached_file :photo, :styles => {:small => "75x75>"},
                    :url => "/assets/products/:id/:style/:basename.:extension",
                    :path => ":rails_root/public/images/users/profiles/:id/:style/:basename.:extension"


  named_scope :users_profiles_all, :include => :user,
              :conditions => "(#{User.table_name}.role_id = #{FeeConst::ROLE_MANAGER} OR #{User.table_name}.role_id = #{FeeConst::ROLE_AUTHOR})"

  named_scope :collaboratori, :conditions => " display_in =#{FeeConst::PROFILO_FS_COLLABORATORE}" # PROFILO_FS_COLLABORATORE = 1
  named_scope :responsabili, :conditions => " display_in =#{FeeConst::PROFILO_FS_RESPONSABILE}" # PROFILO_FS_RESPONSABILE = 2
  named_scope :direttori, :conditions => " display_in =#{FeeConst::PROFILO_FS_DIRETTORE}" # PROFILO_FS_DIRETTORE = 3
  named_scope :invisibili, :conditions => " display_in =#{FeeConst::PROFILO_FS_INVISIBILE}" # PROFILO_FS_INVISIBILE = 4


  def self.user_has_profile?(usr = nil)
    if usr.nil? || (self.users_profiles_all(:first, :conditions => " user_id =#{usr.id}").count == 0)
      false
    else
      true
    end
  end

end

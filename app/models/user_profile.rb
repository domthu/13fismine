class UserProfile < ActiveRecord::Base
  has_attached_file :photo
  belongs_to :user
  attr_accessor :image_file_name, :image_content_type, :image_file_size, :image_updated_at

  named_scope :users_profiles_all, :include => :user,
              :conditions => "#{User.table_name}.role_id = #{FeeConst::ROLE_MANAGER} OR #{User.table_name}.role_id = #{FeeConst::ROLE_AUTHOR}"

=begin
  PROFILO_FS_COLLABORATORE = 1
  PROFILO_FS_RESPONSABILE = 2
  PROFILO_FS_DIRETTORE = 3
  PROFILO_FS_INVISIBILE = 4
=end


  def self.user_has_profile?(usr = nil)
    if usr.nil? || (self.users_profiles_all(:first, :condition => " user_id =#{usr.id}").count == 0)
      false
    else
      true
    end
  end

  def self.profiles_display_collaboratori
    self.users_profiles_all(:first, :condition => " display_in =#{FeeConst::PROFILO_FS_COLLABORATORE}")
  end
  def self.profiles_display_responsabili
    self.users_profiles_all(:first, :condition => " display_in =#{FeeConst::PROFILO_FS_RESPONSABILE}")
  end
  def self.profiles_display_direttori
    self.users_profiles_all(:first, :condition => " display_in =#{FeeConst::PROFILO_FS_DIRETTORE}")
  end
  def self.profiles_display_nothing

    self.users_profiles_all(:first, :condition => " display_in =#{FeeConst::PROFILO_FS_DIRETTORE}")
  end
end

class UserProfile < ActiveRecord::Base
  include GravatarHelper
  require 'digest'
  belongs_to :user
  validates_uniqueness_of :user_id #, :scope => [:type, :project_id]

  has_attached_file :photo, :styles => {:l => ["200x200#", :png, :jpg],
                                        :m => ["80x80#", :png, :jpg],
                                        :s => ["48x48#", :png, :jpg],
                                        :xs =>["32x32#", :png, :jpg]},
                    :url => "users/profile_:id/:style_:basename.:extension",
                    :path => "#{RAILS_ROOT}/public/images/users/profile_:id/:style_:basename.:extension",
                    :default_url => "commons/:style-no_avatar.jpg"

  named_scope :users_profiles_all, :include => :user,
              :conditions => "(#{User.table_name}.role_id = #{FeeConst::ROLE_MANAGER} OR #{User.table_name}.role_id = #{FeeConst::ROLE_AUTHOR})"


  named_scope :collaboratori, :conditions => " display_in =#{FeeConst::PROFILO_FS_COLLABORATORE}", :order => "#{User.table_name}.lastname ASC"   # PROFILO_FS_COLLABORATORE = 1
  named_scope :responsabili, :conditions => " display_in =#{FeeConst::PROFILO_FS_RESPONSABILE}", :order => "#{User.table_name}.lastname ASC" # PROFILO_FS_RESPONSABILE = 2
  named_scope :direttori, :conditions => " display_in =#{FeeConst::PROFILO_FS_DIRETTORE}", :order => "#{User.table_name}.lastname ASC" # PROFILO_FS_DIRETTORE = 3
  named_scope :invisibili, :conditions => " display_in =#{FeeConst::PROFILO_FS_INVISIBILE}", :order => "#{User.table_name}.lastname ASC" # PROFILO_FS_INVISIBILE = 4

  def get_user_profile_id(usr = nil)
    uid = self.users_profiles_all(:first, :conditions => " user_id =#{usr.id}")
    if uid.nil?
         0
    else
      return uid.id
    end
  end

  def self.user_has_profile?(usr = nil)
    if usr.nil? || (self.users_profiles_all(:first, :conditions => " user_id =#{usr.id}").count == 0)
      false
    else
      true
    end
  end

  def uploaded_file=(incoming_file)
    self.filename = incoming_file.original_filename
    self.content_type = incoming_file.content_type
    self.data = incoming_file.read
  end


end

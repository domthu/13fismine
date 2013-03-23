class UserProfile < ActiveRecord::Base
  include GravatarHelper
  require 'digest'
  belongs_to :user
  after_update :reprocess
  has_attached_file :photo, :styles => {:l => ["200x200>", :png, :jpg],
                                        :s => ["80x80>", :png, :jpg],
                                        :xs => ["50x50>", :png, :jpg]},
                    :url => "users/profile_:id/:style_:basename.:extension",
                    :path => "#{RAILS_ROOT}/public/images/users/profile_:id/:style_:basename.:extension",
                    :default_url => "users/profiles/:style_no-img.jpg"

  named_scope :users_profiles_all, :include => :user,
              :conditions => "(#{User.table_name}.role_id = #{FeeConst::ROLE_MANAGER} OR #{User.table_name}.role_id = #{FeeConst::ROLE_AUTHOR})"

  named_scope :collaboratori, :conditions => " display_in =#{FeeConst::PROFILO_FS_COLLABORATORE}" # PROFILO_FS_COLLABORATORE = 1
  named_scope :responsabili, :conditions => " display_in =#{FeeConst::PROFILO_FS_RESPONSABILE}" # PROFILO_FS_RESPONSABILE = 2
  named_scope :direttori, :conditions => " display_in =#{FeeConst::PROFILO_FS_DIRETTORE}" # PROFILO_FS_DIRETTORE = 3
  named_scope :invisibili, :conditions => " display_in =#{FeeConst::PROFILO_FS_INVISIBILE}" # PROFILO_FS_INVISIBILE = 4


  def my_avatar(taglia) #'l per large  ecc
    if self.use_gravatar
      '<div class="fs-my-avatar"> <img src="' + my_gravatar_url(self.user.mail.downcase, taglia) + '" alt="mio-avatar"></div>'
    else
      case taglia
        when :l
          '<div class="fs-my-avatar"> <img src="/images/' + self.photo.url(:l) + '" alt="mio-avatar"></div>'
        when :s
          '<div class="fs-my-avatar"> <img src="/images/' + self.photo.url(:s) + '" alt="mio-avatar"></div>'
        when :xs
          '<div class="fs-my-avatar"> <img src="/images/' + self.photo.url(:xs) + '" alt="mio-avatar"></div>'
        else
          '<div class="fs-my-avatar"> <img src="/images/users/profiles/no_avatars.jpg" alt="mio-avatar"></div>'
      end
    end
  end

  def my_gravatar_url(user, taglia)
    default_url = "#{RAILS_ROOT}images/users/profiles/no_avatars.jpg"
    gravatar_id = Digest::MD5.hexdigest(user)
    case taglia
      when :l
        "http://gravatar.com/avatar/#{gravatar_id.to_s}.png?s=120{CGI.escape(#{default_url})}"
      when :s
        "http://gravatar.com/avatar/#{gravatar_id.to_s}.png?s=80{CGI.escape(#{default_url})}"
      when :xs
        "http://gravatar.com/avatar/#{gravatar_id.to_s}.png?s=50{CGI.escape(#{default_url})}"
      else
        '<div class="fs-my-avatar"> <img src="/images/users/profiles/no_avatars.jpg" alt="mio-avatar"></div>'
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

  def reprocess
    self.photo.reprocess!
  end
end

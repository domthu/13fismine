require "paperclip/railtie"
Paperclip::Railtie.insert
module HasAvatar
  STYLES = {:large => ["200x200#", :png],
            :medium => ["100x100#", :png],
            :small => ["70x70#", :png],
            :little => ["50x50#", :png],
            :tiny => ["24x24#", :png]}

  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def has_avatar
      has_attached_file :avatar,
                        PAPERCLIP_DEFAULTS.merge(
                            :styles => HasAvatar::STYLES,
                            :default_style => :medium,
                            :default_url => "https://assets.presentlyapp.com/images/avatars/missing_:style.png",
                            :path => ":account/avatars/:class/:login/:style.:extension"
                        )
    end
  end
end

require "paperclip/railtie"
Paperclip::Railtie.insert
=begin
module HasAvatar
  STYLES = {:large => ["200x200#", :png, :jpg],
            :medium => ["100x100#", :png,:jpg],
            :small => ["70x70#", :png,:jpg],
            :little => ["50x50#", :png,:jpg],
            :tiny => ["24x24#", :png,:jpg]}

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
ActiveRecord::Base.send :include, HasAvatar
=end
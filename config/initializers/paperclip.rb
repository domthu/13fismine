require "paperclip/railtie"
Paperclip::Railtie.insert
=begin
=end
module HasAvatar
  STYLES_IMG = {:large => ["200x200#", :png, :jpg],
            :medium => ["100x100#", :png,:jpg],
            :small => ["70x70#", :png,:jpg],
            :little => ["50x50#", :png,:jpg],
            :tiny => ["24x24#", :png,:jpg]}
  STYLES_PHOTO = {:l => ["200x200>", :png, :jpg],
                :s => ["75x75>", :png, :jpg]}

  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods

    def has_image
      has_attached_file :image,
          PAPERCLIP_DEFAULTS.merge(
              :styles => HasAvatar::STYLES_IMG,
              :default_style => :medium,
              :url => "articles/:id_:style/:basename.:extension",
              :path => "#{RAILS_ROOT}/public/images/articles/:id_:style/:basename.:extension",
              :default_url => "articles/no-img.jpg"
          )
    end

    def has_foto
      has_attached_file :photo,
          PAPERCLIP_DEFAULTS.merge(
              :styles => HasAvatar::STYLES_PHOTO,
              :default_style => :s,
              :url => "users/profiles/:id/:style/:basename.:extension",
              :path => "#{RAILS_ROOT}/public/images/users/profiles/:id/:style/:basename.:extension",
              :default_url => "users/profiles/:style/missing.png"
          )
    end

  end
end

ActiveRecord::Base.send :include, HasAvatar

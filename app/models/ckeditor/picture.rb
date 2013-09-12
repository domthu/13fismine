class Ckeditor::Picture < Ckeditor::Asset
  unloadable
=begin
  has_attached_file :data,
                    :url  => "/ckeditor_assets/pictures/:id/:style_:basename.:extension",
                    :path => ":rails_root/public/ckeditor_assets/pictures/:id/:style_:basename.:extension",
	                :styles => {:content => '575>', :thumb => '80x80#'}
=end
  has_attached_file :data,
                    :url  => "/images/ckeditor_assets/pictures/:id:style_:basename.:extension",
                    :path => ":rails_root/public/images/ckeditor_assets/pictures/:id:style_:basename.:extension",
 	                :styles => {:content => '575>', :thumb => '80x80#'}

	validates_attachment_size :data, :less_than=>1.megabytes
	
	def url_content
	  url(:content)
	end
	
	def url_thumb
	  url(:thumb)
	end
	
	def to_json(options = {})
	  options[:methods] ||= []
	  options[:methods] << :url_content
	  options[:methods] << :url_thumb
	  super options
  end
end

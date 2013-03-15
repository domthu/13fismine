module AssosHelper

  def smart_truncate2(text, char_limit)
    text = text.squish
    size = 0
    text.mb_chars.split().reject do |token|
      size+=token.size()
      size>char_limit
    end.join(" ") +(text.size()>char_limit ? " "+ "..." : "" )
  end

end

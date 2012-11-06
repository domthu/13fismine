class String
  def to_slug
    ActiveSupport::Inflector.transliterate(self.downcase).gsub(/[^a-zA-Z0-9]+/, '-').gsub(/-{2,}/, '-').gsub(/^-|-$/, '')
  end
end
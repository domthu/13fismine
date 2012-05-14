class AddFieldsToIssue < ActiveRecord::Migration
  def self.up
    add_column :issues, :section_id, :integer
    add_column :issues, :ordinamento, :integer
    add_column :issues, :se_sommario, :boolean
    add_column :issues, :riassunto, :text
    add_column :issues, :titolo, :text
    add_column :issues, :testo, :text
    add_column :issues, :riferimento, :string
    add_column :issues, :se_visible_web, :boolean
    add_column :issues, :data_scadenza, :datetime
    add_column :issues, :se_visible_data, :boolean
    add_column :issues, :se_visible_newsletter, :boolean
    add_column :issues, :se_protetto, :boolean
    add_column :issues, :immagine_url, :string
    add_column :issues, :titolo_no_format, :text
    add_column :issues, :testo_no_format, :text
    add_column :issues, :riassunto_no_format, :text
    add_column :issues, :tag_link, :string
  end

  def self.down
    remove_column :issues, :tag_link
    remove_column :issues, :riassunto_no_format
    remove_column :issues, :testo_no_format
    remove_column :issues, :titolo_no_format
    remove_column :issues, :immagine_url
    remove_column :issues, :se_protetto
    remove_column :issues, :se_visible_newsletter
    remove_column :issues, :se_visible_data
    remove_column :issues, :data_scadenza
    remove_column :issues, :se_visible_web
    remove_column :issues, :riferimento
    remove_column :issues, :testo
    remove_column :issues, :titolo
    remove_column :issues, :riassunto
    remove_column :issues, :se_sommario
    remove_column :issues, :ordinamento
    remove_column :issues, :section_id
  end
end

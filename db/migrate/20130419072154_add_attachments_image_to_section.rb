class AddAttachmentsImageToSection < ActiveRecord::Migration
  def self.up
    add_column :sections, :image_file_name, :string
    add_column :sections, :image_content_type, :string
    add_column :sections, :image_file_size, :integer
    add_column :sections, :image_updated_at, :datetime
    add_column :top_sections, :image_file_name, :string
    add_column :top_sections, :image_content_type, :string
    add_column :top_sections, :image_file_size, :integer
    add_column :top_sections, :image_updated_at, :datetime
    add_column :cross_organizations, :image_file_name, :string
    add_column :cross_organizations, :image_content_type, :string
    add_column :cross_organizations, :image_file_size, :integer
    add_column :cross_organizations, :image_updated_at, :datetime
    add_column :assos, :image_file_name, :string
    add_column :assos, :image_content_type, :string
    add_column :assos, :image_file_size, :integer
    add_column :assos, :image_updated_at, :datetime
    add_column :group_banners, :image_file_name, :string
    add_column :group_banners, :image_content_type, :string
    add_column :group_banners, :image_file_size, :integer
    add_column :group_banners, :image_updated_at, :datetime
    add_column :issues, :image_file_name, :string
    add_column :issues, :image_content_type, :string
    add_column :issues, :image_file_size, :integer
    add_column :issues, :image_updated_at, :datetime
  end

  def self.down
    remove_column :sections, :image_file_name
    remove_column :sections, :image_content_type
    remove_column :sections, :image_file_size
    remove_column :sections, :image_updated_at
    remove_column :top_sections, :image_file_name
    remove_column :top_sections, :image_content_type
    remove_column :top_sections, :image_file_size
    remove_column :top_sections, :image_updated_at
    remove_column :cross_organizations, :image_file_name
    remove_column :cross_organizations, :image_content_type
    remove_column :cross_organizations, :image_file_size
    remove_column :cross_organizations, :image_updated_at
    remove_column :assos, :image_file_name
    remove_column :assos, :image_content_type
    remove_column :assos, :image_file_size
    remove_column :assos, :image_updated_at
    remove_column :group_banners, :image_file_name
    remove_column :group_banners, :image_content_type
    remove_column :group_banners, :image_file_size
    remove_column :group_banners, :image_updated_at
    remove_column :issues, :image_file_name
    remove_column :issues, :image_content_type
    remove_column :issues, :image_file_size
    remove_column :issues, :image_updated_at
  end
end



module AttachmentsHelper

  def link_to_attachments(container, options = {})
    options.assert_valid_keys(:author)

    if container.attachments.any?
      options = {:deletable => container.attachments_deletable?, :author => true}.merge(options)
      render :partial => 'attachments/links', :locals => {:attachments => container.attachments, :options => options}
    end
  end
  def link_to_fs_attachments(container, options = {})
    options.assert_valid_keys(:author)
    if container.attachments.any?
      options = {:deletable => container.attachments_deletable?, :author => true}.merge(options)
      render :partial => 'attachments/art_links', :locals => {:attachments => container.attachments, :options => options}
    end
  end

  def render_api_attachment(attachment, api)
    api.attachment do
      api.id attachment.id
      api.filename attachment.filename
      api.filesize attachment.filesize
      api.content_type attachment.content_type
      api.description attachment.description
      api.content_url url_for(:controller => 'attachments', :action => 'download', :id => attachment, :filename => attachment.filename, :only_path => false)
      api.author(:id => attachment.author.id, :name => attachment.author.name) if attachment.author
      api.created_on attachment.created_on
    end
  end
end

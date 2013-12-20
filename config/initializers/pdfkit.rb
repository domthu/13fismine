
# http://blog.joshsoftware.com/2012/07/25/converting-html-to-pdf/
# https://www.google.it/url?sa=t&rct=j&q=&esrc=s&source=web&cd=12&cad=rja&ved=0CDYQtwIwATgK&url=http%3A%2F%2Fgetmadcat.com%2Fvideo%2F111829%2F220-PDFKit.html&ei=Y6OIUrzJNIvBtAabwIGQCw&usg=AFQjCNFzN6ReIMvQcRnxX2xP1K2a4Dg4mA
PDFKit.configure do |config|
  config.wkhtmltopdf = 'W:\Programs\wkhtmltopdf\wkhtmltopdf.exe'
  config.default_options = {
      :page_size => 'Legal',
      :print_media_type => true ,
      :footer_html => "#{RAILS_ROOT}/app/views/common/footer_pdf.html"

       #  config.root_url = "http://localhost" # Use only if your external hostname is unavailable on the server.
  }
end
=begin  ---remote
PDFKit.configure do |config|
  config.wkhtmltopdf = 'usr/bin/wkhtmltopdf'
  config.default_options = {
    :encoding=>"UTF-8",
    :page_size=>"A4",
    :margin_top=>"0.20in",
    :margin_right=>"0.1in",
    :margin_bottom=>"0.20in",
    :margin_left=>"0.1in",
    :disable_smart_shrinking=> false
  }
=end

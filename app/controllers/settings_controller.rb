# Redmine - project management software
# Copyright (C) 2006-2011  Created by  DomThual & SPecchiaSoft (2013) 
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

class SettingsController < ApplicationController
  layout 'admin'

  before_filter :require_admin

  def index
    edit
    render :action => 'edit'
  end

  def edit
    @notifiables = Redmine::Notifiable.all
    if request.post? && params[:settings] && params[:settings].is_a?(Hash)
      settings = (params[:settings] || {}).dup.symbolize_keys
      settings.each do |name, value|
        # remove blank values in array settings
        value.delete_if { |v| v.blank? } if value.is_a?(Array)
        Setting[name] = value
      end
      up_footer_pdf()
      flash[:notice] = l(:notice_successful_update)
      redirect_to :action => 'edit', :tab => params[:tab]
    else
      @options = {}
      @options[:user_format] = User::USER_FORMATS.keys.collect { |f| [User.current.name(f), f.to_s] }
      @deliveries = ActionMailer::Base.perform_deliveries

      @guessed_host_and_path = request.host_with_port.dup
      @guessed_host_and_path << ('/'+ Redmine::Utils.relative_url_root.gsub(%r{^\/}, '')) unless Redmine::Utils.relative_url_root.blank?

      Redmine::Themes.rescan
    end
  end

  def plugin
    @plugin = Redmine::Plugin.find(params[:id])
    if request.post?
      Setting["plugin_#{@plugin.id}"] = params[:settings]
      flash[:notice] = l(:notice_successful_update)
      redirect_to :action => 'plugin', :id => @plugin.id
    else
      @partial = @plugin.settings[:partial]
      @settings = Setting["plugin_#{@plugin.id}"]
    end
  rescue Redmine::PluginNotFound
    render_404
  end

  def img_refresh_users
    UserProfile.all.each { |s| s.photo.reprocess! }
    redirect_to :action => 'edit', :tab => :display
  end

  def img_refresh_assos
    Asso.all.each { |s| s.image.reprocess! }
    redirect_to :action => 'edit', :tab => :display
  end

  def img_refresh_org
    CrossOrganization.all.each { |s| s.image.reprocess! }
    redirect_to :action => 'edit' , :tab => :display
  end

  def img_refresh_tsection
    TopSection.all.each { |s| s.image.reprocess! }
    redirect_to :action => 'edit' , :tab => :display
  end

  def img_refresh_section
    Section.all.each { |s| s.image.reprocess! }
    redirect_to :action => 'edit' , :tab => :display
  end

  def img_refresh_issues
    Issue.all.each { |s| s.image.reprocess! }
    redirect_to :action => 'edit', :tab => :display
  end
  def img_refresh_banners
    GroupBanner.all.each { |s| s.image.reprocess! }
    redirect_to :action => 'edit', :tab => :display
  end
  def up_footer_pdf
    # WKtoPdf utilizza come footer necessariamente una url che deve puntare necessariamente ad un file html , questo aggiorna il file
    contents = '<html>
      <head>
      <script type="text/javascript">
          function subst() {
        var vars={};
        var x=document.location.search.substring(1).split("&");
        for(var i in x) {var z=x[i].split("=",2);vars[z[0]] = unescape(z[1]);}
        var x=["frompage","topage","page"];
        for(var i in x) {
            var y = document.getElementsByClassName(x[i]);
        for(var j=0; j<y.length; ++j) y[j].textContent = vars[x[i]];
        }
        }
        </script>
</head><body onload="subst();">' + Setting.default_invoices_footer + ' </body></html>'
    #<td> documento<br />
    #	pagina <span class="page"> &nbsp;</span> di <span class="topage">&nbsp;</span></td>
    fname = "#{RAILS_ROOT}/app/views/common/footer_pdf.html"
    somefile = File.open(fname, "w")
    somefile.puts contents
    somefile.close
  end

end

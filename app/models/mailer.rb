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

require 'ar_condition'

class Mailer < ActionMailer::Base
  layout 'mailer'
  layout nil, :only =>  [:newsletter] #, :proposal_meeting]
  helper :application
  helper :issues
  helper :custom_fields

  include ActionController::UrlWriter
  include Redmine::I18n

  def self.default_url_options
    h = Setting.host_name
    h = h.to_s.gsub(%r{\/.*$}, '') unless Redmine::Utils.relative_url_root.blank?
    { :host => h, :protocol => Setting.protocol }
  end

  # Builds a tmail object used to email recipients of the added issue.
  #
  # Example:
  #   issue_add(issue) => tmail object
  #   Mailer.deliver_issue_add(issue) => sends an email to issue recipients
  def issue_add(issue)
    redmine_headers 'Project' => issue.project.identifier,
                    'Issue-Id' => issue.id,
                    'Issue-Author' => issue.author.login
    redmine_headers 'Issue-Assignee' => issue.assigned_to.login if issue.assigned_to
    message_id issue
    recipients issue.recipients
    cc(issue.watcher_recipients - @recipients)
    subject acronym(issue.author) << "[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] (#{issue.status.name}) #{issue.subject}"
    body :issue => issue,
         :issue_url => url_for(:controller => 'issues', :action => 'show', :id => issue)
    render_multipart('issue_add', body)
  end

  # Builds a tmail object used to email recipients of the edited issue.
  #
  # Example:
  #   issue_edit(journal) => tmail object
  #   Mailer.deliver_issue_edit(journal) => sends an email to issue recipients
  def issue_edit(journal)
    issue = journal.journalized.reload
    redmine_headers 'Project' => issue.project.identifier,
                    'Issue-Id' => issue.id,
                    'Issue-Author' => issue.author.login
    redmine_headers 'Issue-Assignee' => issue.assigned_to.login if issue.assigned_to
    message_id journal
    references issue
    @author = journal.user
    recipients issue.recipients
    # Watchers in cc
    cc(issue.watcher_recipients - @recipients)
    s = "[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] "
    s << "(#{issue.status.name}) " if journal.new_value_for('status_id')
    s << issue.subject
    subject acronym(nil) << s
    body :issue => issue,
         :journal => journal,
         :issue_url => url_for(:controller => 'issues', :action => 'show', :id => issue, :anchor => "change-#{journal.id}")

    render_multipart('issue_edit', body)
  end

  def reminder(user, issues, days)
    set_language_if_valid user.language
    recipients user.mail
    subject l(:mail_subject_reminder, :count => issues.size, :days => days)
    body :issues => issues,
         :days => days,
         :issues_url => url_for(:controller => 'issues', :action => 'index',
                                :set_filter => 1, :assigned_to_id => user.id,
                                :sort => 'due_date:asc')
    render_multipart('reminder', body)
  end

  # Builds a tmail object used to email users belonging to the added document's project.
  #
  # Example:
  #   document_added(document) => tmail object
  #   Mailer.deliver_document_added(document) => sends an email to the document's project recipients
  def document_added(document)
    redmine_headers 'Project' => document.project.identifier
    recipients document.recipients
    subject acronym(nil) << "[#{document.project.name}] #{l(:label_document_new)}: #{document.title}"
    body :document => document,
         :document_url => url_for(:controller => 'documents', :action => 'show', :id => document)
    render_multipart('document_added', body)
  end

  # Builds a tmail object used to email recipients of a project when an attachements are added.
  #
  # Example:
  #   attachments_added(attachments) => tmail object
  #   Mailer.deliver_attachments_added(attachments) => sends an email to the project's recipients
  def attachments_added(attachments)
    container = attachments.first.container
    added_to = ''
    added_to_url = ''
    case container.class.name
    when 'Project'
      added_to_url = url_for(:controller => 'files', :action => 'index', :project_id => container)
      added_to = "#{l(:label_project)}: #{container}"
      recipients container.project.notified_users.select {|user| user.allowed_to?(:view_files, container.project)}.collect  {|u| u.mail}
    when 'Version'
      added_to_url = url_for(:controller => 'files', :action => 'index', :project_id => container.project)
      added_to = "#{l(:label_version)}: #{container.name}"
      recipients container.project.notified_users.select {|user| user.allowed_to?(:view_files, container.project)}.collect  {|u| u.mail}
    when 'Document'
      added_to_url = url_for(:controller => 'documents', :action => 'show', :id => container.id)
      added_to = "#{l(:label_document)}: #{container.title}"
      recipients container.recipients
    end
    redmine_headers 'Project' => container.project.identifier
    subject acronym(nil) << "[#{container.project.name}] #{l(:label_attachment_new)}"
    body :attachments => attachments,
         :added_to => added_to,
         :added_to_url => added_to_url
    render_multipart('attachments_added', body)
  end

  # Builds a tmail object used to email recipients of a news' project when a news item is added.
  #
  # Example:
  #   news_added(news) => tmail object
  #   Mailer.deliver_news_added(news) => sends an email to the news' project recipients
  def news_added(news)
    redmine_headers 'Project' => news.project.identifier
    message_id news
    recipients news.recipients
    #Errore in gmail. (Net::SMTPFatalError) 555 5.5.2 Syntax error
    #mettere recipients in questo formato "nome utente <noreply@monaqasat.com>"
    subject acronym(nil) << "[#{news.project.name}] #{l(:label_news)}: #{news.title}"
    body :news => news,
         :news_url => url_for(:controller => 'news', :action => 'show', :id => news)
    render_multipart('news_added', body)
  end

  # Builds a tmail object used to email recipients of a news' project when a news comment is added.
  #
  # Example:
  #   news_comment_added(comment) => tmail object
  #   Mailer.news_comment_added(comment) => sends an email to the news' project recipients
  def news_comment_added(comment)
    news = comment.commented
    redmine_headers 'Project' => news.project.identifier
    message_id comment
    recipients news.recipients
    cc news.watcher_recipients
    subject acronym(nil) << "Re: [#{news.project.name}] #{l(:label_news)}: #{news.title}"
    body :news => news,
         :comment => comment,
         :news_url => url_for(:controller => 'news', :action => 'show', :id => news)
    render_multipart('news_comment_added', body)
  end

  # Builds a tmail object used to email the recipients of the specified message that was posted.
  #
  # Example:
  #   message_posted(message) => tmail object
  #   Mailer.deliver_message_posted(message) => sends an email to the recipients
  def message_posted(message)
    redmine_headers 'Project' => message.project.identifier,
                    'Topic-Id' => (message.parent_id || message.id)
    message_id message
    references message.parent unless message.parent.nil?
    recipients(message.recipients)
    cc((message.root.watcher_recipients + message.board.watcher_recipients).uniq - @recipients)
    subject acronym(nil) << "[#{message.board.project.name} - #{message.board.name} - msg#{message.root.id}] #{message.subject}"
    body :message => message,
         :message_url => url_for(message.event_url)
    render_multipart('message_posted', body)
  end

  # Builds a tmail object used to email the recipients of a project of the specified wiki content was added.
  #
  # Example:
  #   wiki_content_added(wiki_content) => tmail object
  #   Mailer.deliver_wiki_content_added(wiki_content) => sends an email to the project's recipients
  def wiki_content_added(wiki_content)
    redmine_headers 'Project' => wiki_content.project.identifier,
                    'Wiki-Page-Id' => wiki_content.page.id
    message_id wiki_content
    recipients wiki_content.recipients
    cc(wiki_content.page.wiki.watcher_recipients - recipients)
    subject acronym(nil) << "[#{wiki_content.project.name}] #{l(:mail_subject_wiki_content_added, :id => wiki_content.page.pretty_title)}"
    body :wiki_content => wiki_content,
         :wiki_content_url => url_for(:controller => 'wiki', :action => 'show',
                                      :project_id => wiki_content.project,
                                      :id => wiki_content.page.title)
    render_multipart('wiki_content_added', body)
  end

  # Builds a tmail object used to email the recipients of a project of the specified wiki content was updated.
  #
  # Example:
  #   wiki_content_updated(wiki_content) => tmail object
  #   Mailer.deliver_wiki_content_updated(wiki_content) => sends an email to the project's recipients
  def wiki_content_updated(wiki_content)
    redmine_headers 'Project' => wiki_content.project.identifier,
                    'Wiki-Page-Id' => wiki_content.page.id
    message_id wiki_content
    recipients wiki_content.recipients
    cc(wiki_content.page.wiki.watcher_recipients + wiki_content.page.watcher_recipients - recipients)
    subject acronym(nil) << "[#{wiki_content.project.name}] #{l(:mail_subject_wiki_content_updated, :id => wiki_content.page.pretty_title)}"
    body :wiki_content => wiki_content,
         :wiki_content_url => url_for(:controller => 'wiki', :action => 'show',
                                      :project_id => wiki_content.project,
                                      :id => wiki_content.page.title),
         :wiki_diff_url => url_for(:controller => 'wiki', :action => 'diff',
                                   :project_id => wiki_content.project, :id => wiki_content.page.title,
                                   :version => wiki_content.version)
    render_multipart('wiki_content_updated', body)
  end

  # Builds a tmail object used to email the specified user their account information.
  #
  # Example:
  #   account_information(user, password) => tmail object
  #   Mailer.deliver_account_information(user, password) => sends account information to the user
  def account_information(user, password)
    set_language_if_valid user.language
    recipients user.mail
    subject l(:mail_subject_register, Setting.app_title)
    body :user => user,
         :password => password,
         :login_url => url_for(:controller => 'editorial', :action => 'home')
         #:login_url => url_for(:controller => 'account', :action => 'login')
    render_multipart('account_information', body)
  end

  # Builds a tmail object used to email all active administrators of an account activation request.
  #
  # Example:
  #   account_activation_request(user) => tmail object
  #   Mailer.deliver_account_activation_request(user)=> sends an email to all active administrators
  def account_activation_request(user)
    # Send the email to all active administrators
    recipients User.active.find(:all, :conditions => {:admin => true}).collect { |u| u.mail }.compact
    subject l(:mail_subject_account_activation_request, Setting.app_title)
    body :user => user,
         :layout => 'mailer.html.erb',
         :url => url_for(:controller => 'users', :action => 'index',
                         :status => User::STATUS_REGISTERED,
                         :sort_key => 'created_on', :sort_order => 'desc')
    render_multipart('account_activation_request', body)
  end

  # Builds a tmail object used to email the specified user that their account was activated by an administrator.
  #
  # Example:
  #   account_activated(user) => tmail object
  #   Mailer.deliver_account_activated(user) => sends an email to the registered user
  def account_activated(user)
    set_language_if_valid user.language
    recipients user.mail
    subject l(:mail_subject_register, Setting.app_title)
    body :user => user,
         :login_url => url_for(:controller => 'editorial', :action => 'home')
         #:login_url => url_for(:controller => 'account', :action => 'login')
    render_multipart('account_activated', body)
  end

  def lost_password(token)
    set_language_if_valid(token.user.language)
    recipients token.user.mail
    subject l(:mail_subject_lost_password, Setting.app_title)
    body :token => token,
         :url => url_for(:controller => 'account', :action => 'lost_password', :token => token.value)
    render_multipart('lost_password', body)
  end

  #Invio email di confermazione prima di attivare
  def register(token)
    set_language_if_valid(token.user.language)
    recipients token.user.mail
    subject l(:mail_subject_register, Setting.app_title)
    body :token => token,
         :layout => 'mailer.html.erb',
         :url => url_for(:controller => 'account', :action => 'activate', :token => token.value)
    render_multipart('register', body)
  end

  def test(user)
    set_language_if_valid(user.language)
    recipients user.mail
    subject 'Redmine test'
    body :url => url_for(:controller => 'welcome')
    render_multipart('test', body)
  end

  def proposal_meeting (email, user, body_as_string)
    #recipients Setting.fee_bcc_recipients
    recipients Setting.fee_email
    #recipients 'sandro@ks3000495.kimsufi.com'
    #recipients 'domthu@ks3000495.kimsufi.com'
    subject Setting.app_title + ' > Proposta di convegno o di evento'
    if user.logged?
      part :content_type => "text/html",
           :body => '<div style="font-weight:bold;"> User id:[' + user.id.to_s + '] Nome: ' + user.name +  '</div><br /> <hr> <p>'  + body_as_string + '</p>'
    else #user.anonymous?
      part :content_type => "text/html",
           :body => '<div style="font-weight:bold;"> Email:[' + email + '] </div><br /> <hr> <p>'  + body_as_string + '</p>'
    end
=begin
    if user.nil?
      part :content_type => "text/html",
           :body => '<div style="font-wheight:bold;"> Anonymous email:[' + email + '] </div><br /> <hr> <p>'  + body_as_string + '</p>'
    else
      part :content_type => "text/html",
           :body => '<div style="font-wheight:bold;"> User id:[' + user.id.to_s + '] Nome: ' + user.name +  '</div><br /> <hr> <p>'  + body_as_string + '</p>'
    end
=end
  end

  #Via js non vede Application Helper
  def newsletter(user, body_as_string, project)
    from Setting.newsletter_from
    #set_language_if_valid user.language
    recipients user.mail #TODO rimettere in produzione
    #recipients Setting.fee_bcc_recipients
    #recipients Setting.fee_email
    #recipients 'dom.thual@gmail.com'

    ed = ''
    #mail_subject_newsletter: "%{compagny}: %{edizione} del %{date}"
    #ed = user.nil? ? '--' : user.id.to_s
    ed = user.nil? ? '' : ('[' + user.name.html_safe + ']')
    ed += ' '
    ed += project.nil? ? '..' : project.name.html_safe
    ed += ' '
    #subject l(:mail_subject_newsletter, :compagny => Setting.app_title, :edizione => ed, :date => project.data_al)
    subject ed

    ##Kappao (protected method `render_to_string' called for #)
    #if !user.privato?
    #  _html = render_to_string( #undefined method `render_to_string' for #
    #  ac = ActionController::Base.new()
    #  _html = ac.render_to_string(
    #        :layout => false,
    #        :partial => 'editorial/edizione_smtp_convention',
    #        :locals => { :user => user }
    #      )
    #  body_as_string = body_as_string.gsub('@@user_convention@@', _html)
    #end

    clean_html = clean_fs_html(body_as_string, user, project)
    #clean_html = body_as_string
    #ed = user.nil? ? '--' : user.mail
    #clean_html = "<h1>" + ed + "</h1>"+ clean_html
    #subject "invia questa mail"
    #body :token => token,
    #     :url => url_for(:controller => 'account', :action => 'activate', :token => token.value)
    #render_multipart('register', body)

    #content_type "multipart/alternative"
    #Method1 Non usare view
    part :content_type => "text/html",
         :body => clean_html #render_message("#{method_name}.html.erb", body)

    #Method2 usa views
    #body :news => clean_html, :fee_url => url_for(:controller => 'fees'), :app_title => Setting.app_title
    #render_multipart('newsletter', body)
  end

  # Builds a tmail object used to email fee management.
  # layouts/mailer.html.erb:<%= Setting.emails_header
  # Example:
  #   document_added(document) => tmail object
  #   Mailer.deliver_document_added(document) => sends an email to the document's project recipients
  def fee(user, type, setting_text)
    #    * host_name  in settings.xml
    #    * Setting.host_name
    #    * Mailer.default_url_options
    #    * Mailer.X-Redmine-Host
    #redmine_headers 'Project' => 'Abbonamento test'
    recipients user.mail #undefined method `mail' for #<AccountController:0xb42f920c>
    subject Setting.app_title + " > abbonamenti: [#{type}]"
    #body :document => document,
    #     :document_url => url_for(:controller => 'documents', :action => 'show', :id => document)
    #render_multipart('document_added', body)
    #body :fee_type => type, :fee_text => setting_text, :fee_url => url_for(:controller => 'fees')
    clean_html = clean_fs_html(setting_text, user, nil)
    body  :fee_type => type,
          :fee_text => clean_html,
          :fee_url => self.default_url_options
    render_multipart('fee', body)
    #domthu TODO
    # => fee.text.erb
    # => fee.html.erb
    #render_multipart(type, body)
    #TEMPLATE:
    #'proposal'
    #'thanks'
    #'asso'
    #'renew'
  end

  def prova_gratis (user, body_as_string)
    recipients user.mail #TODO rimettere in produzione
    #recipients Setting.fee_bcc_recipients
    #recipients Setting.fee_email
    #recipients 'dom_thual@yahoo.fr'
    subject Setting.app_title + ' > Prova Gratis ' + user.name.html_safe + ' ' + user.mail.html_safe

    html_body = '<div style="font-wheight:bold;padding: 20px 40px; color: #FFF7FF; background-color:#2C4056;"> Info per la segretaria: un utente si è appena registrato id:[' + user.id.to_s + '] Nome: ' + user.name +  '</div><br /><hr><br /><p><h3>Login: '  + user.login + '</h3></p><br /><hr><br /><p><h3>Mail: '  + user.mail + '</h3></p><br /><hr><br /><p><h3>Scadenza: '  + user.scadenza.to_s + ' (' + user.scadenza_fra + ')</h3></p><div>' + body_as_string + '</div>'

    body :html_body => html_body
    render_multipart('prova_gratis', body)
#    content_type "multipart/alternative"
#    part :content_type => "text/html",
#         :body => render(
#               :body => html_body,
#               :layout => 'mailer.html.erb'
#         )

  end

  # Overrides default deliver! method to prevent from sending an email
  # with no recipient, cc or bcc
  def deliver!(mail = @mail)
    set_language_if_valid @initial_language
    if Setting.fee?
      if (recipients.nil? || recipients.empty?)
        recipients Setting.fee_bcc_recipients
      end
      if (recipients.nil? || recipients.empty?)
        recipients Setting.fee_email
      end
    end
    return false if (recipients.nil? || recipients.empty?) &&
                    (cc.nil? || cc.empty?) &&
                    (bcc.nil? || bcc.empty?)

    # Set Message-Id and References
    if @message_id_object
      mail.message_id = self.class.message_id_for(@message_id_object)
    end
    if @references_objects
      mail.references = @references_objects.collect {|o| self.class.message_id_for(o)}
    end

    # Log errors when raise_delivery_errors is set to false, Rails does not
    raise_errors = self.class.raise_delivery_errors
    self.class.raise_delivery_errors = true
    begin
      return super(mail)
    rescue Exception => e
      if raise_errors
        raise e
      elsif mylogger
        mylogger.error "The following error occured while sending email notification: \"#{e.message}\". Check your configuration in config/configuration.yml."
      end
    ensure
      self.class.raise_delivery_errors = raise_errors
    end
  end

  # Sends reminders to issue assignees
  # Available options:
  # * :days     => how many days in the future to remind about (defaults to 7)
  # * :tracker  => id of tracker for filtering issues (defaults to all trackers)
  # * :project  => id or identifier of project to process (defaults to all projects)
  # * :users    => array of user ids who should be reminded
  def self.reminders(options={})
    days = options[:days] || 7
    project = options[:project] ? Project.find(options[:project]) : nil
    tracker = options[:tracker] ? Tracker.find(options[:tracker]) : nil
    user_ids = options[:users]

    s = ARCondition.new ["#{IssueStatus.table_name}.is_closed = ? AND #{Issue.table_name}.due_date <= ?", false, days.day.from_now.to_date]
    s << "#{Issue.table_name}.assigned_to_id IS NOT NULL"
    s << ["#{Issue.table_name}.assigned_to_id IN (?)", user_ids] if user_ids.present?
    s << "#{Project.table_name}.status = #{Project::STATUS_ACTIVE}"
    s << "#{Issue.table_name}.project_id = #{project.id}" if project
    s << "#{Issue.table_name}.tracker_id = #{tracker.id}" if tracker

    issues_by_assignee = Issue.find(:all, :include => [:status, :assigned_to, :project, :tracker],
                                          :conditions => s.conditions
                                    ).group_by(&:assigned_to)
    issues_by_assignee.each do |assignee, issues|
      deliver_reminder(assignee, issues, days) if assignee.is_a?(User) && assignee.active?
    end
  end

  # Activates/desactivates email deliveries during +block+
  def self.with_deliveries(enabled = true, &block)
    was_enabled = ActionMailer::Base.perform_deliveries
    ActionMailer::Base.perform_deliveries = !!enabled
    yield
  ensure
    ActionMailer::Base.perform_deliveries = was_enabled
  end

  private
  def initialize_defaults(method_name)
    super
    @initial_language = current_language
    set_language_if_valid Setting.default_language
    from Setting.mail_from

    # Common headers
    headers 'X-Mailer' => 'Redmine',
            'X-Redmine-Host' => Setting.host_name,
            'X-Redmine-Site' => Setting.app_title,
            'X-Auto-Response-Suppress' => 'OOF',
            'Auto-Submitted' => 'auto-generated'
  end

  # Appends a Redmine header field (name is prepended with 'X-Redmine-')
  def redmine_headers(h)
    h.each { |k,v| headers["X-Redmine-#{k}"] = v }
  end

  # Overrides the create_mail method
  def create_mail
    # Removes the current user from the recipients and cc
    # if he doesn't want to receive notifications about what he does
    @author ||= User.current
    if @author.pref[:no_self_notified]
      recipients.delete(@author.mail) if recipients
      cc.delete(@author.mail) if cc
    end

    notified_users = [recipients, cc].flatten.compact.uniq
    mylogger.info "Sending email notification to: #{notified_users.join(', ')}" if mylogger

    # Blind carbon copy recipients
    if Setting.bcc_recipients?
      bcc(notified_users)
      recipients []
      cc []
    end
    super
  end

  # Rails 2.3 has problems rendering implicit multipart messages with
  # layouts so this method will wrap an multipart messages with
  # explicit parts.
  #
  # https://rails.lighthouseapp.com/projects/8994/tickets/2338-actionmailer-mailer-views-and-content-type
  # https://rails.lighthouseapp.com/projects/8994/tickets/1799-actionmailer-doesnt-set-template_format-when-rendering-layouts

  def render_multipart(method_name, body)
    if Setting.plain_text_mail?
      content_type "text/plain"
      body render(:file => "#{method_name}.text.erb",
                  :body => body,
                  :layout => 'mailer.text.erb')
    else
      content_type "multipart/alternative"
      part :content_type => "text/plain",
           :body => render(:file => "#{method_name}.text.erb",
                           :body => body, :layout => 'mailer.text.erb')
      #part :content_type => "text/html",
      #     :body => render_message("#{method_name}.html.erb", body)
      part :content_type => "text/html",
           :body => render(:file => "#{method_name}.html.erb",
                           :body => body, :layout => 'mailer.html.erb')
    end
  end

  # Makes partial rendering work with Rails 1.2 (retro-compatibility)
  def self.controller_path
    ''
  end unless respond_to?('controller_path')

  # Returns a predictable Message-Id for the given object
  def self.message_id_for(object)
    # id + timestamp should reduce the odds of a collision
    # as far as we don't send multiple emails for the same object
    timestamp = object.send(object.respond_to?(:created_on) ? :created_on : :updated_on)
    hash = "redmine.#{object.class.name.demodulize.underscore}-#{object.id}.#{timestamp.strftime("%Y%m%d%H%M%S")}"
    host = Setting.mail_from.to_s.gsub(%r{^.*@}, '')
    host = "#{::Socket.gethostname}.redmine" if host.empty?
    "<#{hash}@#{host}>"
  end

  def acronym(user)
    if user && !user.nil?
      return user.acronimo
    elsif User.current && !User.current.nil?
      return User.current.acronimo
    end
    return ""
  end

  #se lo metto dentro application helper
  #allora la chiamata def newslletter fatta via js non vede application helper
  def clean_fs_html(txt, user, prj)
    #if txt.include? '@@distance_of_date_in_words@@'
    if user
      txt = txt.gsub('@@user_username@@', user.name)
      if user.password.nil?
        txt = txt.gsub('@@user_password@@', '?')
      else
        txt = txt.gsub('@@user_password@@', user.password)
      end
      if user.scadenza
        #txt = txt.gsub('@@user_scadenza@@', user.scadenza) expected numeric
        #txt = txt.gsub('@@user_scadenza@@', get_short_date(user.scadenza) #undefined method `get_short_date' for #)
        txt = txt.gsub('@@user_scadenza@@', format_date(user.scadenza))
        txt = txt.gsub('@@distance_of_date_in_words@@', user.scadenza_fra)
      else
        txt = txt.gsub('@@user_scadenza@@', ' -non definita- ')
        txt = txt.gsub('@@distance_of_date_in_words@@', ' -non definita- ')
      end
      txt = txt.gsub('@@user_codice@@', user.id.to_s)
      if !user.privato? && user.convention
        txt = txt.gsub('@@user_convention@@', "Sei conventionato a " + user.convention.name)
        if user.convention.user
          txt = txt.gsub('@@poweruser_username@@', user.convention.user.name)
          txt = txt.gsub('@@poweruser_codice@@', user.convention.user.id.to_s)
        end
      else
        txt = txt.gsub('@@user_convention@@', '')
        txt = txt.gsub('@@poweruser_username@@', '')
        txt = txt.gsub('@@poweruser_codice@@', '')
      end
    else
      txt = txt.gsub('@@user_username@@', '')
      txt = txt.gsub('@@user_password@@', '')
      txt = txt.gsub('@@user_scadenza@@', '')
      txt = txt.gsub('@@distance_of_date_in_words@@', '')
      txt = txt.gsub('@@user_codice@@', '')
      txt = txt.gsub('@@user_convention@@', '')
      txt = txt.gsub('@@poweruser_username@@', '')
      txt = txt.gsub('@@poweruser_codice@@', '')
    end
    if User.current
      txt = txt.gsub('@@logged_username@@',  User.current.name)
      txt = txt.gsub('@@logged_state@@',  User.current.state)
    else
      txt = txt.gsub('@@logged_username@@', '')
      txt = txt.gsub('@@logged_state@@', '')
    end
    txt = txt.gsub('@@settings_host_name@@',  Setting.host_name )
    txt = txt.gsub('@@settings_register_days@@',  Setting.register_days.to_s )
    txt = txt.gsub('@@settings_renew_days@@',  Setting.renew_days.to_s )
    txt = txt.gsub('@@settings_fee_bcc_recipients@@',  Setting.fee_bcc_recipients )
    txt = txt.gsub('@@settings_fee_email@@',  Setting.fee_email )
    txt = txt.gsub('@@settings_app_title@@',  Setting.app_title )
    txt = txt.gsub('@@settings_welcome_text_fs@@',  Setting.welcome_text_fs )
    txt = txt.gsub('@@settings_welcome_text@@',  Setting.welcome_text )
    return txt
  end

  def message_id(object)
    @message_id_object = object
  end

  def references(object)
    @references_objects ||= []
    @references_objects << object
  end

  def mylogger
    Rails.logger
  end

end

# Patch TMail so that message_id is not overwritten
module TMail
  class Mail
    def add_message_id( fqdn = nil )
      self.message_id ||= ::TMail::new_message_id(fqdn)
    end
  end
end

require 'redmine/access_control'
require 'redmine/menu_manager'
require 'redmine/activity'
require 'redmine/search'
require 'redmine/custom_field_format'
require 'redmine/mime_type'
require 'redmine/core_ext'
require 'redmine/themes'
require 'redmine/hook'
require 'redmine/plugin'
require 'redmine/notifiable'
require 'redmine/wiki_formatting'
require 'redmine/scm/base'

begin
  require_library_or_gem 'RMagick' unless Object.const_defined?(:Magick)
rescue LoadError
  # RMagick is not available
end

if RUBY_VERSION < '1.9'
  require 'faster_csv'
else
  require 'csv'
  FCSV = CSV
end

Redmine::Scm::Base.add "Subversion"
Redmine::Scm::Base.add "Darcs"
Redmine::Scm::Base.add "Mercurial"
Redmine::Scm::Base.add "Cvs"
Redmine::Scm::Base.add "Bazaar"
Redmine::Scm::Base.add "Git"
Redmine::Scm::Base.add "Filesystem"

Redmine::CustomFieldFormat.map do |fields|
  fields.register Redmine::CustomFieldFormat.new('string', :label => :label_string, :order => 1)
  fields.register Redmine::CustomFieldFormat.new('text', :label => :label_text, :order => 2)
  fields.register Redmine::CustomFieldFormat.new('int', :label => :label_integer, :order => 3)
  fields.register Redmine::CustomFieldFormat.new('float', :label => :label_float, :order => 4)
  fields.register Redmine::CustomFieldFormat.new('list', :label => :label_list, :order => 5)
  fields.register Redmine::CustomFieldFormat.new('date', :label => :label_date, :order => 6)
  fields.register Redmine::CustomFieldFormat.new('bool', :label => :label_boolean, :order => 7)
  fields.register Redmine::CustomFieldFormat.new('user', :label => :label_user, :only => %w(Issue TimeEntry Version Project), :edit_as => 'list', :order => 8)
  fields.register Redmine::CustomFieldFormat.new('version', :label => :label_version, :only => %w(Issue TimeEntry Version Project), :edit_as => 'list', :order => 9)
end

# Permissions
Redmine::AccessControl.map do |map|
  #domthu permission :access_back_end, :welcome => :index, :require => :loggedin
  #This permissions are at role level and not at project level
  map.permission :fee_control, :welcome => :index, :require => :loggedin, :public => true
  map.permission :access_back_end, :welcome => :index, :require => :loggedin
  map.permission :front_end_quesito, :editorial => :quesito_nuovo, :require => :loggedin
  map.permission :view_project, {:projects => [:show], :activities => [:index]}, :public => true
  map.permission :search_project, {:search => :index}, :public => true
  map.permission :add_project, {:projects => [:new, :create]}, :require => :loggedin
  map.permission :edit_project, {:projects => [:settings, :edit, :update]}, :require => :member
  map.permission :select_project_modules, {:projects => :modules}, :require => :member
  map.permission :manage_members, {:projects => :settings, :members => [:new, :edit, :destroy, :autocomplete_for_member]}, :require => :member
  map.permission :manage_versions, {:projects => :settings, :versions => [:new, :create, :edit, :update, :close_completed, :destroy]}, :require => :member
  map.permission :add_subprojects, {:projects => [:new, :create]}, :require => :member

  map.project_module :issue_tracking do |map|
    # Issue categories
    map.permission :manage_categories, {:projects => :settings, :issue_categories => [:index, :show, :new, :create, :edit, :update, :destroy]}, :require => :member
    # Issues
    map.permission :view_issues, {:issues => [:index, :show],
                                  :auto_complete => [:issues],
                                  :context_menus => [:issues],
                                  :versions => [:index, :show, :status_by],
                                  :journals => [:index, :diff],
                                  :queries => :index,
                                  :reports => [:issue_report, :issue_report_details]}
    map.permission :add_issues, {:issues => [:new, :create, :update_form]}
    map.permission :edit_issues, {:issues => [:edit, :update, :bulk_edit, :bulk_update, :update_form], :journals => [:new]}
    map.permission :manage_issue_relations, {:issue_relations => [:index, :show, :create, :destroy]}
    map.permission :manage_subtasks, {}
    map.permission :set_issues_private, {}
    map.permission :set_own_issues_private, {}, :require => :loggedin
    map.permission :add_issue_notes, {:issues => [:edit, :update], :journals => [:new]}
    map.permission :edit_issue_notes, {:journals => :edit}, :require => :loggedin
    map.permission :edit_own_issue_notes, {:journals => :edit}, :require => :loggedin
    map.permission :move_issues, {:issue_moves => [:new, :create, :news_fast_reply], :issues => [:news_fast_reply]}, :require => :loggedin
    map.permission :delete_issues, {:issues => :destroy}, :require => :member
    # Queries
    map.permission :manage_public_queries, {:queries => [:new, :create, :edit, :update, :destroy]}, :require => :member
    map.permission :save_queries, {:queries => [:new, :create, :edit, :update, :destroy]}, :require => :loggedin
    # Watchers
    map.permission :view_issue_watchers, {}
    map.permission :add_issue_watchers, {:watchers => :new}
    map.permission :delete_issue_watchers, {:watchers => :destroy}
  end

  map.project_module :time_tracking do |map|
    map.permission :log_time, {:timelog => [:new, :create]}, :require => :loggedin
    map.permission :view_time_entries, :timelog => [:index, :show], :time_entry_reports => [:report]
    map.permission :edit_time_entries, {:timelog => [:edit, :update, :destroy, :bulk_edit, :bulk_update]}, :require => :member
    map.permission :edit_own_time_entries, {:timelog => [:edit, :update, :destroy, :bulk_edit, :bulk_update]}, :require => :loggedin
    map.permission :manage_project_activities, {:project_enumerations => [:update, :destroy]}, :require => :member
  end

  map.project_module :news do |map|
    map.permission :manage_news, {:news => [:new, :create, :edit, :update, :destroy], :comments => [:destroy]}, :require => :member
    map.permission :view_news, {:news => [:index, :show]}, :public => true
    map.permission :comment_news, {:comments => :create}
  end

  map.project_module :documents do |map|
    map.permission :manage_documents, {:documents => [:new, :edit, :destroy, :add_attachment]}, :require => :loggedin
    map.permission :view_documents, :documents => [:index, :show, :download]
  end

  map.project_module :files do |map|
    map.permission :manage_files, {:files => [:new, :create]}, :require => :loggedin
    map.permission :view_files, :files => :index, :versions => :download
  end

  map.project_module :wiki do |map|
    map.permission :manage_wiki, {:wikis => [:edit, :destroy]}, :require => :member
    map.permission :rename_wiki_pages, {:wiki => :rename}, :require => :member
    map.permission :delete_wiki_pages, {:wiki => :destroy}, :require => :member
    map.permission :view_wiki_pages, :wiki => [:index, :show, :special, :date_index]
    map.permission :export_wiki_pages, :wiki => [:export]
    map.permission :view_wiki_edits, :wiki => [:history, :diff, :annotate]
    map.permission :edit_wiki_pages, :wiki => [:edit, :update, :preview, :add_attachment]
    map.permission :delete_wiki_pages_attachments, {}
    map.permission :protect_wiki_pages, {:wiki => :protect}, :require => :member
  end

  map.project_module :repository do |map|
    map.permission :manage_repository, {:repositories => [:edit, :committers, :destroy]}, :require => :member
    map.permission :browse_repository, :repositories => [:show, :browse, :entry, :annotate, :changes, :diff, :stats, :graph]
    map.permission :view_changesets, :repositories => [:show, :revisions, :revision]
    map.permission :commit_access, {}
  end

  map.project_module :boards do |map|
    map.permission :manage_boards, {:boards => [:new, :edit, :destroy]}, :require => :member
    map.permission :view_messages, {:boards => [:index, :show], :messages => [:show]}, :public => true
    map.permission :add_messages, {:messages => [:new, :reply, :quote]}
    map.permission :edit_messages, {:messages => :edit}, :require => :member
    map.permission :edit_own_messages, {:messages => :edit}, :require => :loggedin
    map.permission :delete_messages, {:messages => :destroy}, :require => :member
    map.permission :delete_own_messages, {:messages => :destroy}, :require => :loggedin
  end

  map.project_module :calendar do |map|
    map.permission :view_calendar, :calendars => [:show, :update]
  end

  map.project_module :gantt do |map|
    map.permission :view_gantt, :gantts => [:show, :update]
  end
end

Redmine::MenuManager.map :top_menu do |menu|
  menu.push :home_fs, :editorial_path
  menu.push :home, :home_path, :if => Proc.new { User.current.logged? }
  #domthu 20120517
  #menu.push :section, :sections_path
  #menu.push :my_page, :table_path
  menu.push :my_page, {:controller => 'my', :action => 'page'}, :if => Proc.new { User.current.logged? }
  menu.push :projects, {:controller => 'projects', :action => 'index'}, :caption => :label_project_plural, :if => Proc.new { User.current.logged? }
  menu.push :activity, {:controller => 'activities', :action => 'index'}, :caption => :label_activity_plural, :if => Proc.new { User.current.logged? }
  #menu.push :forum, Setting.host_name + "/projects/sys-quesiti", :if => Proc.new { !Project.find_by_identifier('sys-quesiti').nil? }
  menu.push :administration, {:controller => 'admin', :action => 'index'}, :if => Proc.new { User.current.admin? }, :last => true
 # menu.push :calendar, {:controller => 'calendars', :action => 'show'}, :param => :project_id, :caption => :label_calendar
  #menu.push :help, Redmine::Info.help_url, :last => true
  menu.push :help, Redmine::Info.help_url, :if => Proc.new { User.current.admin? }, :html => {:target => '_blank'}
  menu.push :help_user, Redmine::Info.help_user_url, :if => Proc.new { User.current.admin? }, :html => {:target => '_blank'}
end
#:html => {:onclick => 'return showTour();', :target => '_blank'}

Redmine::MenuManager.map :top_menu_fs do |menu|
  menu.push :public_site_home, :editorial_path
  menu.push :home, :home_path, :if => Proc.new { User.current.logged? && User.current.allowed_to?(:access_back_end, nil, :global => true) }
  menu.push :my_page, {:controller => 'my', :action => 'page'}, :if => Proc.new { User.current.logged? && User.current.allowed_to?(:access_back_end, nil, :global => true) }
  menu.push :projects, {:controller => 'editorial', :action => 'edizioni'}, :caption => :label_project_plural
  #menu.push :issues, { :controller => 'editorial', :action => 'articoli' }, :caption => :label_issue_plural
  #menu.push :news, { :controller => 'editorial', :action => 'quesiti' }, :caption => :label_news_plural
  menu.push :quesito_nuovo, {:controller => 'editorial', :action => 'quesito_nuovo'}, :if => Proc.new { User.current.logged? && User.current.allowed_to?(:front_end_quesito, nil, :global => true) }
  menu.push :aboutus, :about_path
  menu.push :faq, :help_path
  menu.push :contact, :contact_path
  menu.push :login, :signin_path, :if => Proc.new { !User.current.logged? }
  menu.push :register, {:controller => 'account', :action => 'register'}, :if => Proc.new { !User.current.logged? && Setting.self_registration? }
  menu.push :mio_profilo, {:controller => 'mio_profilo', :action => 'account'}, :if => Proc.new { User.current.logged? }
  menu.push :logout, :signout_path, :if => Proc.new { User.current.logged? }

end

Redmine::MenuManager.map :footer_menu_fs do |menu|
  #menu.push :editoriale, :editorial_path see custom routes
  menu.push :edizioni, :edizioni_path
  menu.push :articoli, :articoli_path
  menu.push :quesiti, :quesiti_path
  menu.push :quesito_nuovo, :poniquesito_path
  menu.push :contact, :contact_path
  menu.push :about, :about_path
  menu.push :help, :help_path
  menu.push :ricerca, :ricerca_path
  #menu.push :registrazione, :registrazione_path
  #menu.push :accedi, :accedi_path
  menu.push :edizione, :edizione_path
  #menu.push :articolo, :articolo_path see custom routes
  menu.push :quesito_full, :quesito_path
end

# < sandro >

Redmine::MenuManager.map :account_fe_menu do |menu|
  menu.push :login, :signin_path, :if => Proc.new { !User.current.logged? }
  menu.push :register, {:controller => 'account', :action => 'register'}, :if => Proc.new { !User.current.logged? && Setting.self_registration? }
  menu.push :mio_profilo, {:controller => 'mio_profilo', :action => 'account'}, :if => Proc.new { User.current.logged? }
  menu.push :logout, :signout_path, :if => Proc.new { User.current.logged? }
end

# < end sandro >


Redmine::MenuManager.map :account_menu do |menu|
  menu.push :login, :signin_path, :if => Proc.new { !User.current.logged? }
  menu.push :register, {:controller => 'account', :action => 'register'}, :if => Proc.new { !User.current.logged? && Setting.self_registration? }
  menu.push :my_account, {:controller => 'my', :action => 'account'}, :if => Proc.new { User.current.logged? }
  menu.push :logout, :signout_path, :if => Proc.new { User.current.logged? }
end

Redmine::MenuManager.map :application_menu do |menu|
  # Empty
  #menu fiscosport
  menu.push :table_fs, :conventions_path, :if => Proc.new { User.current.admin? }
  #menu abbonamento
  menu.push :fee_manage, :fee_path, :if => Proc.new { User.current.admin? && Setting.fee? }
  #menu.push :fee_manage, :registrati_path, :if => Proc.new { User.current.admin? && Setting.fee? }
  #menu pagamenti
  menu.push :payment, :invoices_path, :if => Proc.new { User.current.admin? && Setting.fee? }
end
##----------------------------------
# MENU LATERALE DX(admministrator)
##----------------------------------
Redmine::MenuManager.map :admin_menu do |menu|
  #menu fiscosport
  menu.push :table_fs, :conventions_path
  #menu abbonamento
  menu.push :abbo, {:controller => 'fees', :action => 'index'}, :caption => :label_abbo_plural, :if => Proc.new { Setting.fee? }
  #menu.push :abbo, {:controller => 'fees', :action => 'registrati'}, :caption => :label_abbo_plural, :if => Proc.new { Setting.fee? }
  menu.push :invoices, :invoices_path, :caption => :label_invoice_plural,  :if => Proc.new {  User.current.admin?}
  #menu.push :projects, {:controller => 'admin', :action => 'projects'}, :caption => :label_project_plural
  menu.push :users, {:controller => 'users'}, :caption => :label_user_plural
  menu.push :comunes, :comunes_path, :caption => :label_comune_plural, :if => Proc.new { User.current.admin? }
  menu.push :groups, {:controller => 'groups'}, :caption => :label_group_plural
  menu.push :roles, {:controller => 'roles'}, :caption => :label_role_and_permissions
  menu.push :trackers, {:controller => 'trackers'}, :caption => :label_tracker_plural
  menu.push :issue_statuses, {:controller => 'issue_statuses'}, :caption => :label_issue_status_plural,
            :html => {:class => 'issue_statuses'}
  menu.push :workflows, {:controller => 'workflows', :action => 'edit'}, :caption => :label_workflow
  menu.push :custom_fields, {:controller => 'custom_fields'}, :caption => :label_custom_field_plural,
            :html => {:class => 'custom_fields'}
  menu.push :enumerations, {:controller => 'enumerations'}
  menu.push :settings, {:controller => 'settings'}
  menu.push :ldap_authentication, {:controller => 'ldap_auth_sources', :action => 'index'},
            :html => {:class => 'server_authentication'}
  menu.push :plugins, {:controller => 'admin', :action => 'plugins'}, :last => true
  menu.push :info, {:controller => 'admin', :action => 'info'}, :caption => :label_information_plural, :last => true
end

Redmine::MenuManager.map :project_menu do |menu|
  menu.push :overview, {:controller => 'projects', :action => 'show'}
  menu.push :activity, {:controller => 'activities', :action => 'index'}
  menu.push :roadmap, {:controller => 'versions', :action => 'index'}, :param => :project_id,
            :if => Proc.new { |p| p.shared_versions.any? }
  menu.push :issues, {:controller => 'issues', :action => 'index'}, :param => :project_id, :caption => :label_issue_plural
  menu.push :new_issue, {:controller => 'issues', :action => 'new'}, :param => :project_id, :caption => :label_issue_new,
            :html => {:accesskey => Redmine::AccessKeys.key_for(:new_issue)}
  menu.push :gantt, {:controller => 'gantts', :action => 'show'}, :param => :project_id, :caption => :label_gantt
  menu.push :calendar, {:controller => 'calendars', :action => 'show'}, :param => :project_id, :caption => :label_calendar
  menu.push :news, {:controller => 'news', :action => 'index'}, :param => :project_id, :caption => :label_news_plural
  menu.push :documents, {:controller => 'documents', :action => 'index'}, :param => :project_id, :caption => :label_document_plural
  menu.push :wiki, {:controller => 'wiki', :action => 'show', :id => nil}, :param => :project_id,
            :if => Proc.new { |p| p.wiki && !p.wiki.new_record? }
  menu.push :boards, {:controller => 'boards', :action => 'index', :id => nil}, :param => :project_id,
            :if => Proc.new { |p| p.boards.any? }, :caption => :label_board_plural
  menu.push :files, {:controller => 'files', :action => 'index'}, :caption => :label_file_plural, :param => :project_id
  menu.push :repository, {:controller => 'repositories', :action => 'show'},
            :if => Proc.new { |p| p.repository && !p.repository.new_record? }
  menu.push :settings, {:controller => 'projects', :action => 'settings'}, :last => true
end
# MENU LATERALE DX-> ABBONAMENTI
Redmine::MenuManager.map :menu_fee_fs do |menu|
  menu.push :fee, :fee_path, :caption => :label_overview
  menu.push :liste_utenti, :liste_utenti_path , :caption => :list_registrati
  menu.push :associati, :associati_path  , :caption => :who_not_pay
  menu.push :paganti, :paganti_path   , :caption => :who_pay
 # menu.push :abbonamenti, :abbonamenti_path
 # #menu.push :scaduti, :scaduti_path
 #menu.push :archiviati, :archiviati_path
end
# MENU LATERALE DX -> FATTURE
Redmine::MenuManager.map :menu_payment_fs do |menu|
  menu.push :invoices, :invoices_path, :caption =>  :label_invoice_plural , :if => Proc.new { User.current.admin? }
  menu.push :invoice_receiver, :invoice_receiver_path , :caption =>  :label_invoice_new , :if => Proc.new { User.current.admin? }
  #menu.push :contract, :contracts_path, :if => Proc.new { User.current.admin? }
  #menu.push :contract_per_user, :contract_users_path, :if => Proc.new { User.current.admin? }
  menu.push :payments, :payments_path , :caption => :label_pagamento_metodo_plural, :if => Proc.new { User.current.admin? }
  menu.push :email_fee, :email_fee_path, :caption => :label_fee_templates, :if => Proc.new { User.current.admin? }
  end
# MENU LATERALE DX -> FISCOSPORT
Redmine::MenuManager.map :menu_fiscosport do |menu|
  menu.push :top_menus, :top_menus_path, :caption => :label_top_menu, :if => Proc.new { User.current.admin? }
  menu.push :top_sections, :top_sections_path, :caption => :label_top_section_plural, :if => Proc.new { User.current.admin? }
  menu.push :sections, :sections_path, :caption => :label_section_plural, :if => Proc.new { User.current.admin? }
  menu.push :type_organizations, :type_organizations_path, :caption => :label_type_organization_plural, :if => Proc.new { User.current.admin? }
  menu.push :cross_organizations, :cross_organizations_path, :caption => :label_cross_organization_plural, :if => Proc.new { User.current.admin? }
  menu.push :conventions, :conventions_path, :caption => :label_convention_plural, :if => Proc.new { User.current.admin? }
  menu.push :group_banners, :group_banners_path, :caption => :label_group_banner_plural, :if => Proc.new { User.current.admin? }
end
# MENU LATERALE DX -> COMUNI
Redmine::MenuManager.map :menu_comuni do |menu|
  menu.push :comunes, :comunes_path, :caption => :label_comune_plural, :if => Proc.new { User.current.admin? }
  menu.push :provinces, :provinces_path, :caption => :label_province_plural, :if => Proc.new { User.current.admin? }
  menu.push :regions, :regions_path, :caption => :label_region_plural, :if => Proc.new { User.current.admin? }
end
# pagina principale vista
#pagina lista utenti con relativi azione
#selettore di ruolo
#ricerca per utente
#filtro data scadenza
#export
## admin
#  ROLE_MANAGER        = 3  #Manager<br />
#  ROLE_AUTHOR         = 4  #Redattore  <br />
#  #ROLE_COLLABORATOR   = 4  #ROLE_REDATTORE   autore, redattore e collaboratore tutti uguali<br />
#  ROLE_VIP            = 10 #Invitato Gratuito<br />

#  ROLE_ABBONATO       = 6  #Abbonato user.data_scadenza > (today - Setting.renew_days)<br />
#  ROLE_REGISTERED     = 9  #Ospite periodo di prova durante Setting.register_days<br />
#  ROLE_RENEW          = 11  #Rinnovo: periodo prima della scadenza dipende da Setting.renew_days<br />
#  ROLE_EXPIRED        = 7  #Scaduto: user.data_scadenza < today<br />
#  ROLE_ARCHIVIED      = 8  #Archiviato: bloccato: puo uscire da questo stato solo manualmente ("Ha pagato", "invito di


Redmine::Activity.map do |activity|
  activity.register :issues, :class_name => %w(Issue Journal)
  activity.register :changesets
  activity.register :news
  activity.register :documents, :class_name => %w(Document Attachment)
  activity.register :files, :class_name => 'Attachment'
  activity.register :wiki_edits, :class_name => 'WikiContent::Version', :default => false
  activity.register :messages, :default => false
  activity.register :time_entries, :default => false
end

Redmine::Search.map do |search|
  search.register :issues
  search.register :news
  search.register :documents
  search.register :changesets
  search.register :wiki_pages
  search.register :messages
  search.register :projects
  search.register_fs :issues
  search.register_fs :news
  search.register_fs :projects
end

Redmine::WikiFormatting.map do |format|
  format.register :textile, Redmine::WikiFormatting::Textile::Formatter, Redmine::WikiFormatting::Textile::Helper
end

ActionView::Template.register_template_handler :rsb, Redmine::Views::ApiTemplateHandler

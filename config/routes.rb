ActionController::Routing::Routes.draw do |map|
  map.resources :newsletter_users
  map.resources :newsletters
  map.resources :pages
  map.resources :user_profiles
  map.resources :reservations
#http://guides.rubyonrails.org/v2.3.11/routing.html
#rake routes | grep -r "lost_password"
  map.resources :top_menus
  map.resources :contract_users
  map.resources :contracts
  map.resources :templates
  map.resources :reservations
  #  under are only for paperclip images refresh
  map.with_options :controller => 'settings' do |img|
    img.with_options :conditions => {:method => :post} do |img_model|
      img_model.connect 'settings', :action => 'img_refresh_users' , :tab =>  'display'
      img_model.connect 'settings', :action => 'img_refresh_assos' , :tab =>  'display'
      img_model.connect 'settings', :action => 'img_refresh_org'  , :tab =>  'display'
      img_model.connect 'settings', :action => 'img_refresh_tsection' , :tab =>  'display'
      img_model.connect 'settings', :action => 'img_refresh_section' , :tab =>  'display'
      img_model.connect 'settings', :action => 'img_refresh_issues'  , :tab =>  'display'
    end
    end
  #----------------------------------------------------------------------------------
  #map.resources :autocomplete_searches, :only => [:index], :as => 'autocomplete'
  #AJAX get usando JQuery UI autocomplete
  map.usertitle 'usertitle', :controller => 'services', :action => 'Usertitle', :conditions => {:method => [:get]}
  #AJAX post usando JQuery
  map.emailctrl 'emailctrl', :controller => 'services', :action => 'emailctrl', :conditions => {:method => [:get]}
  map.privacy 'privacy', :controller => 'services', :action => 'privacy', :conditions => {:method => [:get]}
  map.condition 'condition', :controller => 'services', :action => 'condition', :conditions => {:method => [:get]}
  map.webdesigner 'webdesigner', :controller => 'services', :action => 'webdesigner', :conditions => {:method => [:get]}
  map.zone 'zone', :controller => 'services', :action => 'zone', :conditions => {:method => [:get]}
  map.zone_extend 'zone_extend', :controller => 'services', :action => 'zone_extend', :conditions => {:method => [:get]}

  #TODO Organismi e assosvc --> ConventionSvc
  map.organismi 'organismi', :controller => 'services', :action => 'organismi', :conditions => {:method => [:get]}
  map.assosvc 'assosvc', :controller => 'services', :action => 'assosvc', :conditions => {:method => [:get]}

  map.tiposigla 'tiposigla', :controller => 'services', :action => 'tiposigla', :conditions => {:method => [:get]}
  map.art_extend 'art_extend', :controller => 'services', :action => 'articolo_extend', :conditions => {:method => [:get]}

  map.my_profile_show 'my_profile_show', :controller => 'mio_profilo', :action => 'page'
  map.my_profile_edit 'my_profile_edit', :controller => 'mio_profilo', :action => 'account'

  # If not authorized home_url --> editorial_url
  map.home '', :controller => 'welcome' #REDMINE HOME
  map.oldhome '/Index.aspx', :controller => 'welcome' #old url fiscosport.it/Index.asp
  map.oldsendmail '/SendMail.aspx', :controller => 'welcome' #old url fiscosport.it/Index.asp
  #map.home '/editoriale/home', :controller => "editorial", :action => 'home' #FRONT END
  #map.home'',  :controller => "editorial", :action => 'top_menu',  :topmenu_key =>  "fiscale" #"approfondimenti -->non c'è questa voce in TopMenu?" #FRONT END

  # Named Routes for static pages.
  map.cosaoffriamo '/cosa-offriamo', :controller => 'editorial', :action => 'pages_cosa-offriamo'
  map.contattaci '/contattaci', :controller => 'editorial', :action => 'pages_contattaci'
  map.newsport  '/news-sport', :controller => 'editorial', :action => 'newsport'
  map.progettofs  '/progetto-fiscosport', :controller => 'editorial', :action => 'pages_progetto-fs'
  map.lavoraconnoi '/lavora-con-noi', :controller => 'editorial', :action => 'pages_lavora-con-noi'
  map.page_abbonamento '/account/abbonati-a-fiscosport', :controller => 'editorial', :action => 'pages_abbonamenti'
   #-> Edizioni e Newletter (table: projects)-
  map.edizioni '/edizioni', :controller => 'editorial', :action => 'edizioni'
  map.edizione '/edizione/:id', :controller => 'editorial', :action => 'edizione'
  map.edizione_newsletter '/edizione_newsletter/:id', :controller => 'editorial', :action => 'edizione_newsletter'
  #-> Convegni ed Eventi ()topsection_id=9) -
  map.evento '/evento/:id/:slug', :controller => 'editorial', :action => 'evento'
  map.eventi '/eventi', :controller => 'editorial', :action => 'eventi'
  map.propose_evt 'propose_evt', :controller => 'editorial', :action => 'send_proposal_meeting', :conditions => {:method => [:post]}

  #-> Quesiti (table: news)-
  map.quesiti_all '/quesiti', :controller => 'editorial', :action => 'quesiti_all'
  map.quesito_show '/quesito/:id', :controller => 'editorial', :action => 'quesito_show'
  map.quesito_new '/quesito_new', :controller => 'editorial', :action => 'quesito_new'
  map.quesito_create '/quesito_create', :controller => 'editorial', :action => 'quesito_create'
  map.quesiti_my '/quesiti_my', :controller => 'editorial', :action => 'quesiti_my'
  #-> Quesiti (table: user_profiles)-
  map.profiles_all '/chi-siamo',:controller => 'editorial', :action => 'profili_all'
  map.profile_new '/chi-siamo/profilo/new', :controller => 'editorial', :action => 'profilo_new'
  map.profile_show '/chi-siamo/profilo/:id', :controller => 'editorial', :action => 'profilo_show'
  map.profile_edit '/chi-siamo/profilo/:id/edit', :controller => 'editorial', :action => 'profilo_edit'
  map.profile_destroy '/chi-siamo/profilo/:id/destroy', :controller => 'editorial', :action => 'profilo_destroy'
  map.profile_update '/chi-siamo/profilo/:id/update', :controller => 'editorial', :action => 'profilo_update'
  map.ricerca '/ricerca', :controller => 'editorial', :action => 'ricerca'
  map.unsubscribe '/account/unsubscribe', :controller => 'account', :action => 'unsubscribe'
  map.unauthorized '/unauthorized', :controller => 'editorial', :action => 'unauthorized'
  map.prova_gratis 'prova_gratis', :controller => 'account', :action => 'prova', :conditions => {:method => [:post]}
  map.banners_position '/group_banners/position',:controller => 'group_banners', :action=> 'positions', :conditions => {:method => [:get]}
=begin
  map.with_options :controller => 'editorial' , :conditions => {:method => :get} do |user_profiles_views|
      user_profiles_views.connect '/chi-siamo', :action => 'profili_all'
      user_profiles_views.connect '/chi-siamo/profilo/new', :action => 'profilo_new'
      user_profiles_views.connect '/chi-siamo/profilo/:id', :action => 'profilo_show'
      user_profiles_views.connect '/chi-siamo/profilo/edit/:id', :action => 'profilo_edit'
    end
  map.with_options :controller => 'user_profiles' , :conditions => {:method => :post} do |user_profiles_actions|
      user_profiles_actions.connect '/profilo', :action => 'create_profile'
      user_profiles_actions.connect '/profilo', :action => 'update_profile'
    end
=end

#Map menu

  map.nlmailer '/nlmailer/:newsletter_id', :controller => 'services', :action => 'nlmailer'
  map.newsletter_massmailer '/massmailer/:newsletter_id', :controller => 'newsletters', :action => 'massmailer'
  #via js
  #map.newsletter_send_emails '/send_emails/:newsletter_id/:pageSize', :controller => 'newsletters', :action => 'send_emails'
  map.newsletter_send_emails '/send_emails', :controller => 'newsletters', :action => 'send_emails'
  map.newsletter_removeemails '/removeemails/:newsletter_id/:type', :controller => 'newsletters', :action => 'removeemails'


  map.newsletter_invii '/invii/:project_id',
                      :controller => 'newsletters',
                      :action => 'invii',
                      :project_id => /\d.+/,
                      #:project_id => /[^\/]+/,
                      :conditions => {:method => [:get, :post]}

  map.editorial '/editoriale/home',
                :controller => 'editorial',
                :action => 'home'

  #Pretty URLs (http://apidock.com/rails/v2.3.8/ActionController/Routing)

  map.top_menu_page '/editoriale/:topmenu_key',
                    :controller => 'editorial',
                    :action => 'top_menu',
                    :topmenu_key => /[^\/]+/


  map.topsection_page '/editoriale/:topmenu_key/:topsection_key',
                      :controller => 'editorial',
                      :action => 'top_sezione',
                      :topmenu_key => /[^\/]+/,
                      :topsection_key => /[^\/]+/,
                      :conditions => {:method => [:get, :post]}


#  map.articolo_page 'editorial/:top_menu_key/sezione/:top_section_id/articolo/:article_id',

  map.articolo_page '/editoriale/:topmenu_key/:topsection_key/:article_id/:article_slug',
                    :controller => 'editorial',
                    :action => 'articolo',
                    :topmenu_key => /[^\/]+/,
                    :topsection_key => /[^\/]+/,
                    :article_id => /\d.+/,
                    :article_slug => /[^\/]+/,
                    :conditions => {:method => [:get, :post]}


  map.resources :regions
  #map.resources :provinces
  map.resources :provinces, :has_many => :regions
  #map.resources :comunes
  map.resources :comunes, :has_many => :provinces
  map.resources :group_banners

  map.resources :conventions
  map.resources :cross_organizations
  map.resources :type_organizations

  map.resources :sections
  map.resources :top_sections

  map.resources :invoices
  map.fee 'fee', :controller => 'fees', :action => 'index'
  map.liste_utenti 'liste_utenti', :controller => 'fees', :action => 'liste_utenti'
  map.scaduti 'scaduti', :controller => 'fees', :action => 'scaduti'
  map.archiviati 'archiviati', :controller => 'fees', :action => 'archiviati'
  map.invia_fatture 'invia_fatture', :controller => 'fees', :action => 'invia_fatture'
  map.paganti 'paganti', :controller => 'fees', :action => 'paganti'
  map.privati 'privati', :controller => 'fees', :action => 'privati'
  map.associati 'associati', :controller => 'fees', :action => 'associati'
  map.email_fee 'email_fee', :controller => 'fees', :action => 'email_fee', :conditions => {:method => :get}
  map.email_fee_goto_settings 'email_fee_settings', :controller => 'settings', :action => 'edit', :tab => 'fee'
  map.static_pages_settings 'email_fee_settings', :controller => 'settings', :action => 'edit', :tab => 'static_pages'
  map.abbonamenti 'abbonamenti', :controller => 'fees', :action => 'abbonamenti'
  #in POST not in Get for params[:username]...
  #map.signin 'login', :controller => 'account', :action => 'login'
  #map.signout 'logout', :controller => 'account', :action => 'logout'
  map.signin 'login', :controller => 'account', :action => 'login',
             :conditions => {:method => [:get, :post]}
  map.signout 'logout', :controller => 'account', :action => 'logout',
              :conditions => {:method => :get}
  map.connect 'account/register', :controller => 'account', :action => 'register',
              :conditions => {:method => [:get, :post]}
  map.connect 'account/lost_password', :controller => 'account', :action => 'lost_password',
              :conditions => {:method => [:get, :post]}
  map.connect 'account/activate', :controller => 'account', :action => 'activate',
              :conditions => {:method => :get}

  map.connect 'roles/workflow/:id/:role_id/:tracker_id', :controller => 'roles', :action => 'workflow'
  map.connect 'help/:ctrl/:page', :controller => 'help'

  map.with_options :controller => 'time_entry_reports', :action => 'report',:conditions => {:method => :get} do |time_report|
    time_report.connect 'projects/:project_id/issues/:issue_id/time_entries/report'
    time_report.connect 'projects/:project_id/issues/:issue_id/time_entries/report.:format'
    time_report.connect 'projects/:project_id/time_entries/report'
    time_report.connect 'projects/:project_id/time_entries/report.:format'
    time_report.connect 'time_entries/report'
    time_report.connect 'time_entries/report.:format'
  end

  map.bulk_edit_time_entry 'time_entries/bulk_edit',
                   :controller => 'timelog', :action => 'bulk_edit', :conditions => { :method => :get }
  map.bulk_update_time_entry 'time_entries/bulk_edit',
                   :controller => 'timelog', :action => 'bulk_update', :conditions => { :method => :post }
  map.time_entries_context_menu '/time_entries/context_menu',
                   :controller => 'context_menus', :action => 'time_entries'
  # TODO: wasteful since this is also nested under issues, projects, and projects/issues
  map.resources :time_entries, :controller => 'timelog'

  map.connect 'projects/:id/wiki', :controller => 'wikis', :action => 'edit', :conditions => {:method => :post}
  map.connect 'projects/:id/wiki/destroy', :controller => 'wikis', :action => 'destroy', :conditions => {:method => :get}
  map.connect 'projects/:id/wiki/destroy', :controller => 'wikis', :action => 'destroy', :conditions => {:method => :post}

  map.with_options :controller => 'messages' do |messages_routes|
    messages_routes.with_options :conditions => {:method => :get} do |messages_views|
      messages_views.connect 'boards/:board_id/topics/new', :action => 'new'
      messages_views.connect 'boards/:board_id/topics/:id', :action => 'show'
      messages_views.connect 'boards/:board_id/topics/:id/edit', :action => 'edit'
    end
    messages_routes.with_options :conditions => {:method => :post} do |messages_actions|
      messages_actions.connect 'boards/:board_id/topics/new', :action => 'new'
      messages_actions.connect 'boards/:board_id/topics/:id/replies', :action => 'reply'
      messages_actions.connect 'boards/:board_id/topics/:id/:action', :action => /edit|destroy/
    end
  end

  map.with_options :controller => 'boards' do |board_routes|
    board_routes.with_options :conditions => {:method => :get} do |board_views|
      board_views.connect 'projects/:project_id/boards', :action => 'index'
      board_views.connect 'projects/:project_id/boards/new', :action => 'new'
      board_views.connect 'projects/:project_id/boards/:id', :action => 'show'
      board_views.connect 'projects/:project_id/boards/:id.:format', :action => 'show'
      board_views.connect 'projects/:project_id/boards/:id/edit', :action => 'edit'
    end
    board_routes.with_options :conditions => {:method => :post} do |board_actions|
      board_actions.connect 'projects/:project_id/boards', :action => 'new'
      board_actions.connect 'projects/:project_id/boards/:id/:action', :action => /edit|destroy/
    end
  end

  map.with_options :controller => 'documents' do |document_routes|
    document_routes.with_options :conditions => {:method => :get} do |document_views|
      document_views.connect 'projects/:project_id/documents', :action => 'index'
      document_views.connect 'projects/:project_id/documents/new', :action => 'new'
      document_views.connect 'documents/:id', :action => 'show'
      document_views.connect 'documents/:id/edit', :action => 'edit'
    end
    document_routes.with_options :conditions => {:method => :post} do |document_actions|
      document_actions.connect 'projects/:project_id/documents', :action => 'new'
      document_actions.connect 'documents/:id/:action', :action => /destroy|edit/
    end
  end

  map.resources :issue_moves, :only => [:new, :create], :path_prefix => '/issues', :as => 'move'
  map.resources :queries, :except => [:show]

  # Misc issue routes. TODO: move into resources
  map.auto_complete_issues '/issues/auto_complete', :controller => 'auto_completes', :action => 'issues', :conditions => { :method => :get }
  map.preview_issue '/issues/preview/:id', :controller => 'previews', :action => 'issue' # TODO: would look nicer as /issues/:id/preview
  map.preview_fs_articolo '/editorial/articolo/:article_id', :controller => 'editorial', :action => 'preview_articolo'
  map.preview_articolo '/issues/articolo/:id', :controller => 'previews', :action => 'articolo'
  map.preview_newsletter '/newsletter_preview/:user_id', :controller => 'previews', :action => 'newsletter'
  map.unassigned_users '/unassigned_users', :controller => 'previews', :action => 'norole'
  map.emailed_users '/emailed_users/:type/:id', :controller => 'previews', :action => 'nlemailed'

  map.issues_context_menu '/issues/context_menu', :controller => 'context_menus', :action => 'issues'
  map.issue_changes '/issues/changes', :controller => 'journals', :action => 'index'
  map.bulk_edit_issue 'issues/bulk_edit', :controller => 'issues', :action => 'bulk_edit', :conditions => { :method => :get }
  map.bulk_update_issue 'issues/bulk_edit', :controller => 'issues', :action => 'bulk_update', :conditions => { :method => :post }
  map.quoted_issue '/issues/:id/quoted', :controller => 'journals', :action => 'new', :id => /\d+/, :conditions => { :method => :post }
  map.connect '/issues/:id/destroy', :controller => 'issues', :action => 'destroy', :conditions => { :method => :post } # legacy

  map.with_options :controller => 'gantts', :action => 'show' do |gantts_routes|
    gantts_routes.connect '/projects/:project_id/issues/gantt'
    gantts_routes.connect '/projects/:project_id/issues/gantt.:format'
    gantts_routes.connect '/issues/gantt.:format'
  end

  map.with_options :controller => 'calendars', :action => 'show' do |calendars_routes|
    calendars_routes.connect '/projects/:project_id/issues/calendar'
    calendars_routes.connect '/issues/calendar'
  end

  map.with_options :controller => 'reports', :conditions => {:method => :get} do |reports|
    reports.connect 'projects/:id/issues/report', :action => 'issue_report'
    reports.connect 'projects/:id/issues/report/:detail', :action => 'issue_report_details'
  end

  # Following two routes conflict with the resources because #index allows POST
  map.connect '/issues', :controller => 'issues', :action => 'index', :conditions => { :method => :post }
  map.connect '/issues/create', :controller => 'issues', :action => 'index', :conditions => { :method => :post }

  map.resources :issues, :member => { :edit => :post }, :collection => {} do |issues|
    issues.resources :time_entries, :controller => 'timelog'
    issues.resources :relations, :shallow => true, :controller => 'issue_relations', :only => [:index, :show, :create, :destroy]
  end

  map.resources :issues, :path_prefix => '/projects/:project_id', :collection => { :create => :post } do |issues|
    issues.resources :time_entries, :controller => 'timelog'
  end

  map.connect 'projects/:id/members/new', :controller => 'members', :action => 'new'

  map.with_options :controller => 'users' do |users|
    users.connect 'users/:id/edit/:tab', :action => 'edit', :tab => nil, :conditions => {:method => :get}

    users.with_options :conditions => {:method => :post} do |user_actions|
      user_actions.connect 'users/:id/memberships', :action => 'edit_membership'
      user_actions.connect 'users/:id/memberships/:membership_id', :action => 'edit_membership'
      user_actions.connect 'users/:id/memberships/:membership_id/destroy', :action => 'destroy_membership'
    end
  end

  map.resources :users, :member => {
    :edit_membership => :post,
    :destroy_membership => :post
  }

  # For nice "roadmap" in the url for the index action
  map.connect 'projects/:project_id/roadmap', :controller => 'versions', :action => 'index'

  map.all_news 'news', :controller => 'news', :action => 'index'
  map.formatted_all_news 'news.:format', :controller => 'news', :action => 'index'
  map.preview_news '/news/preview', :controller => 'previews', :action => 'news'
  map.connect 'news/:id/comments', :controller => 'comments', :action => 'create', :conditions => {:method => :post}
  map.connect 'news/:id/comments/:comment_id', :controller => 'comments', :action => 'destroy', :conditions => {:method => :delete}

  #map.assign_collaboratore 'news/assign', :controller => 'news', :action => 'assegna' , :conditions => {:method => :put}
  #map.fast_reply 'issues/fast_reply', :controller => 'issues', :action => 'news_fast_reply'
  #map.fast_reply 'quesito/fast_reply', :controller => 'issue_moves', :action => 'news_fast_reply'
  map.fast_reply 'quesito/fast_reply', :controller => 'news', :action => 'news_fast_reply'

  map.resources :projects, :member => {
    :copy => [:get, :post],
    :settings => :get,
    :modules => :post,
    :archive => :post,
    :unarchive => :post
  } do |project|
    project.resource :project_enumerations, :as => 'enumerations', :only => [:update, :destroy]
    project.resources :files, :only => [:index, :new, :create]
    project.resources :versions, :shallow => true, :collection => {:close_completed => :put}, :member => {:status_by => :post}
    project.resources :news, :shallow => true
    project.resources :time_entries, :controller => 'timelog', :path_prefix => 'projects/:project_id'
    project.resources :queries, :only => [:new, :create]
    project.resources :issue_categories, :shallow => true

    project.wiki_start_page 'wiki', :controller => 'wiki', :action => 'show', :conditions => {:method => :get}
    project.wiki_index 'wiki/index', :controller => 'wiki', :action => 'index', :conditions => {:method => :get}
    project.wiki_diff 'wiki/:id/diff/:version', :controller => 'wiki', :action => 'diff', :version => nil
    project.wiki_diff 'wiki/:id/diff/:version/vs/:version_from', :controller => 'wiki', :action => 'diff'
    project.wiki_annotate 'wiki/:id/annotate/:version', :controller => 'wiki', :action => 'annotate'
    project.resources :wiki, :except => [:new, :create], :member => {
      :rename => [:get, :post],
      :history => :get,
      :preview => :any,
      :protect => :post,
      :add_attachment => :post
    }, :collection => {
      :export => :get,
      :date_index => :get
    }

  end

  # Destroy uses a get request to prompt the user before the actual DELETE request
  map.project_destroy_confirm 'projects/:id/destroy', :controller => 'projects', :action => 'destroy', :conditions => {:method => :get}

  # TODO: port to be part of the resources route(s)
  map.with_options :controller => 'projects' do |project_mapper|
    project_mapper.with_options :conditions => {:method => :get} do |project_views|
      project_views.connect 'projects/:id/settings/:tab', :controller => 'projects', :action => 'settings'
      project_views.connect 'projects/:project_id/issues/:copy_from/copy', :controller => 'issues', :action => 'new'
    end
  end

  map.with_options :controller => 'activities', :action => 'index', :conditions => {:method => :get} do |activity|
    activity.connect 'projects/:id/activity'
    activity.connect 'projects/:id/activity.:format'
    activity.connect 'activity', :id => nil
    activity.connect 'activity.:format', :id => nil
  end

  map.with_options :controller => 'repositories' do |repositories|
    repositories.with_options :conditions => {:method => :get} do |repository_views|
      repository_views.connect 'projects/:id/repository', :action => 'show'
      repository_views.connect 'projects/:id/repository/edit', :action => 'edit'
      repository_views.connect 'projects/:id/repository/statistics', :action => 'stats'
      repository_views.connect 'projects/:id/repository/revisions', :action => 'revisions'
      repository_views.connect 'projects/:id/repository/revisions.:format', :action => 'revisions'
      repository_views.connect 'projects/:id/repository/revisions/:rev', :action => 'revision'
      repository_views.connect 'projects/:id/repository/revisions/:rev/diff', :action => 'diff'
      repository_views.connect 'projects/:id/repository/revisions/:rev/diff.:format', :action => 'diff'
      repository_views.connect 'projects/:id/repository/revisions/:rev/raw/*path', :action => 'entry', :format => 'raw', :requirements => { :rev => /[a-z0-9\.\-_]+/ }
      repository_views.connect 'projects/:id/repository/revisions/:rev/:action/*path', :requirements => { :rev => /[a-z0-9\.\-_]+/ }
      repository_views.connect 'projects/:id/repository/raw/*path', :action => 'entry', :format => 'raw'
      # TODO: why the following route is required?
      repository_views.connect 'projects/:id/repository/entry/*path', :action => 'entry'
      repository_views.connect 'projects/:id/repository/:action/*path'
    end

    repositories.connect 'projects/:id/repository/:action', :conditions => {:method => :post}
  end

  map.resources :attachments, :only => [:show, :destroy]
  # additional routes for having the file name at the end of url
  map.connect 'attachments/:id/:filename', :controller => 'attachments', :action => 'show', :id => /\d+/, :filename => /.*/
  map.connect 'attachments/download/:id/:filename', :controller => 'attachments', :action => 'download', :id => /\d+/, :filename => /.*/

  map.resources :groups, :member => {:autocomplete_for_user => :get}
  map.group_users 'groups/:id/users', :controller => 'groups', :action => 'add_users', :id => /\d+/, :conditions => {:method => :post}
  map.group_user  'groups/:id/users/:user_id', :controller => 'groups', :action => 'remove_user', :id => /\d+/, :conditions => {:method => :delete}

  map.resources :trackers, :except => :show
  map.resources :issue_statuses, :except => :show, :collection => {:update_issue_done_ratio => :post}

  #left old routes at the bottom for backwards compat
  map.connect 'projects/:project_id/issues/:action', :controller => 'issues'
  map.connect 'projects/:project_id/documents/:action', :controller => 'documents'
  map.connect 'projects/:project_id/boards/:action/:id', :controller => 'boards'
  map.connect 'boards/:board_id/topics/:action/:id', :controller => 'messages'
  map.connect 'wiki/:id/:page/:action', :page => nil, :controller => 'wiki'
  map.connect 'projects/:project_id/news/:action', :controller => 'news'
  map.connect 'projects/:project_id/timelog/:action/:id', :controller => 'timelog', :project_id => /.+/
  map.with_options :controller => 'repositories' do |omap|
    omap.repositories_show 'repositories/browse/:id/*path', :action => 'browse'
    omap.repositories_changes 'repositories/changes/:id/*path', :action => 'changes'
    omap.repositories_diff 'repositories/diff/:id/*path', :action => 'diff'
    omap.repositories_entry 'repositories/entry/:id/*path', :action => 'entry'
    omap.repositories_entry 'repositories/annotate/:id/*path', :action => 'annotate'
    omap.connect 'repositories/revision/:id/:rev', :action => 'revision'
  end

  map.with_options :controller => 'sys' do |sys|
    sys.connect 'sys/projects.:format', :action => 'projects', :conditions => {:method => :get}
    sys.connect 'sys/projects/:id/repository.:format', :action => 'create_project_repository', :conditions => {:method => :post}
  end

  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id'
  map.connect 'robots.txt', :controller => 'welcome', :action => 'robots'
  # Used for OpenID
  map.root :controller => 'account', :action => 'login'
end

ActionController::Routing::Routes.draw do |map|
  map.resources :top_menus

  map.resources :contract_users

  map.resources :contracts

  map.resources :contracts

  map.resources :templates

  # If not authorized home_url --> editorial_url
  map.home '', :controller => 'welcome'   #REDMINE HOME
 # map.root :controller => "editorial", :action => 'top_menu', :id => 1 ,  :path => '/home/:id'  #FRONT END
  #map.root :controller => "editorial", :action => 'home'   #FRONT END

  # Named Routes for static pages.
  map.contact       '/contact',  :controller => 'editorial', :action => 'contact'
  map.about         '/about',    :controller => 'editorial', :action => 'about'
  map.help          '/help',     :controller => 'editorial', :action => 'help'
  map.edizioni      '/edizioni', :controller => 'editorial', :action => 'edizioni'
  map.edizione      '/edizione/:id', :controller => 'editorial', :action => 'edizione'
  map.articoli      '/articoli', :controller => 'editorial', :action => 'articoli'
  #map.registrazione '/registrazione', :controller => 'editorial', :action => 'register'
  #map.accedi        '/accedi', :controller => 'editorial', :action => 'login'
  map.quesiti       '/quesiti', :controller => 'editorial', :action => 'quesiti'
  map.quesito       '/quesito/:id', :controller => 'editorial', :action => 'quesito'
  map.poniquesito   '/poniquesito', :controller => 'editorial', :action => 'poniquesito'
  map.ricerca       '/ricerca', :controller => 'editorial', :action => 'ricerca'
  map.unauthorized       '/unauthorized', :controller => 'editorial', :action => 'unauthorized'

#http://guides.rubyonrails.org/v2.3.11/routing.html
#map.resources :photos, :path_prefix => '/photographers/:photographer_id'
#map.resources :users, :path_prefix => '/:locale'
#link_to 'English', url_for( :locale => 'en' )
#link_to 'Deutch', url_for( :locale => 'de' )
#Map menu
  #map.editorial '/home/prima-pagina'
  #            :controller => 'editorial',
  #            :action     => 'home'
  #map.connect '/editorial/home',
  #map.editorial '/home',
  map.editorial '/editoriale/home',
              :controller => 'editorial',
              :action     => 'home'

  #Pretty URLs (http://apidock.com/rails/v2.3.8/ActionController/Routing)

  map.top_menu_page '/editoriale/:topmenu_key',
              :controller   => 'editorial',
              :action       => 'top_menu',
              :topmenu_key  => /[^\/]+/


  map.topsection_page '/editoriale/:topmenu_key/:topsection_key',

              :controller   => 'editorial',
              :action       => 'top_sezione',
              :topmenu_key  => /[^\/]+/,
              :topsection_key   => /[^\/]+/,
              :conditions => {:method => [:get, :post]}


#  map.articolo_page 'editorial/:top_menu_key/sezione/:top_section_id/articolo/:article_id',

  map.articolo_page '/editoriale/:topmenu_key/:topsection_key/:article_id',
              :controller       => 'editorial',
              :action           => 'articolo',
              :topmenu_key      => /[^\/]+/,
              :topsection_key   => /[^\/]+/,
              :article_id       => /\d.+/,
              :conditions => {:method => [:get, :post]}




#  map.topsection_page '/editorial/:topmenu_key/sezione/:topsection_id',
#              :controller   => 'editorial',
#              :action       => 'top_sezione',
#              :topmenu_key  => /[^\/]+/,  # /\d{4}/,
               # --> sandro fix problema visulizzazione routing su top section
#              :topsection_id   => /[0-9]+/,
#              :conditions => {:method => [:get, :post]}
#              :as => 'topsection_page'

#  map.articolo_page 'editorial/:top_menu_key/articolo/:article_id',
#              :controller       => 'editorial',
#              :action           => 'articolo',
#              :top_menu_key      => /[^\/]+/,  # /\d{4}/,
#              :top_section_id    => /\d.+/,
#              :article_id       => /\d.+/,
#              :conditions => {:method => [:get, :post]}
#              :article_title    => /[^\/]+/  # /\d{1,2}/
#              :as => 'articolo_page'




  map.resources :regions
  #map.resources :provinces
  map.resources :provinces, :has_many => :regions
  #map.resources :comunes
  map.resources :comunes, :has_many => :provinces

  map.resources :cross_groups
  map.resources :group_banners
  map.resources :assos

  map.resources :organizations
  map.resources :cross_organizations
  map.resources :type_organizations

  map.resources :sections
  map.resources :top_sections

  map.resources :invoices
  map.fee 'fee', :controller => 'fees', :action => 'index'
  map.registrati 'registrati', :controller => 'fees', :action => 'registrati'
  map.scaduti 'scaduti', :controller => 'fees', :action => 'scaduti'
  map.archiviati 'archiviati', :controller => 'fees', :action => 'archiviati'
  map.pagamento 'pagamento', :controller => 'fees', :action => 'pagamento'
  map.invia_fatture 'invia_fatture', :controller => 'fees', :action => 'invia_fatture'
  map.paganti 'paganti', :controller => 'fees', :action => 'paganti'
  map.privati 'privati', :controller => 'fees', :action => 'privati'
  map.associati 'associati', :controller => 'fees', :action => 'associati'
  map.email_fee 'email_fee', :controller => 'fees', :action => 'email_fee', :conditions => {:method => :get}
  map.email_fee_goto_settings 'email_fee_settings', :controller => 'settings', :action => 'edit', :tab => 'fee'

  #in POST not in Get for params[:username]...
  map.abbonamenti 'abbonamenti', :controller => 'fees', :action => 'abbonamenti'

  map.signin 'home-login', :controller => 'account', :action => 'login'
  map.signout 'logout', :controller => 'account', :action => 'logout'



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

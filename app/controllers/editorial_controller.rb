class EditorialController < ApplicationController
  layout 'editorial'
  #before_filter :require_admin
  helper :sort
  include SortHelper
  include FeesHelper #ROLE_XXX

  before_filter :find_optional_project, :only => [:ricerca]
  before_filter :correct_user, :only => [:articolo, :quesito_full]
  before_filter :enabled_user, :only => [:articolo, :quesito_full]

  helper :messages
  include MessagesHelper

  caches_action :robots

  #HOME > TOP_MENU > TOP_SECTION > SECTION > ARTICOLO
  def home
    @xbanner = GroupBanner.find(:all, :order => 'priorita DESC', :conditions => ["se_visibile = 1"])
    @base_url = params[:pages]
#    @last_editorial = Project.visible.find(:all, :order => 'lft')
#    @p = Project.find(:first, :order => 'created_on DESC')
#    @projects = Project.all.compact.uniq
#    @link_project = Project.find_by_identifier($1) || Project.find_by_name($1)
    @block_projects = Project.latest_fs
    @projects = Project.latest_fs
# @issues = Issue.latest_fs
# Paginate results
    case params[:format]
      when 'xml', 'json'
        @offset, @limit = api_offset_and_limit
      else
        @limit = 5
        @offset= 25
    end
# --> sandro debug zona
    @top_menu = TopMenu.find(:first, :conditions => 'id =1')
    @topsection_ids = TopSection.find(:all,
                                      :select => 'distinct id',
                                      :conditions => ["top_menu_id =  ?", @top_menu.id]
    )
# -->
    @issues_count =Issue.count(
        :include => [:section => :top_section]
    )
    @issues_pages = Paginator.new self, @issues_count, @limit, params['page']
    @issues = Issue.find(:all,
                         :include => [:section => :top_section],
                         :order => 'updated_on DESC',
                         :conditions => ["se_visible_web = 1 AND is_private = 0"],
                         :limit => @issues_pages.items_per_page,
                         :offset => @issues_pages.current.offset)


    respond_to do |format|
      format.html {
        render :layout => !request.xhr?
      }
      format.api

    end
    #MariaCristina Non mostrare i quesiti nella home page
    #@news = News.latest_fs
    #<div class="splitcontentleft">
    #  <% if @news.any? %>
    #  <div class="news box">
    #  <h3><%=l(:label_news_latest)%></h3>
    #    <%= render :partial => 'news/news', :collection => @news %>
    #    <%= link_to l(:label_news_view_all), :action => 'quesiti' %>
    #  </div>
    #  <% end %>
    #  <%= call_hook(:view_welcome_index_left, :projects => @projects) %>
    #</div>
  end

  def top_menu
    @base_url = params[:pages]
    @key_url = params[:topmenu_key]
    if @key_url.nil?
      flash[:notice] = l(:notice_missing_parameters) + " --> 1"
      redirect_to :action => 'home'
      return
    elsif @key_url == "home"
      redirect_to :action => 'home'
      return
    end
    @top_menu = TopMenu.find(:first, :conditions => ["`key` = ?", @key_url])
    if @top_menu.nil?
      flash[:notice] = l(:notice_missing_parameters) + " --> 2 @key_url="+ @key_url
      # redirect_to :action => 'home'
      return
    end
    #@top_sections = TopSection.find(:all,
    @topsection_ids = TopSection.find(:all,
                                      :select => 'distinct id',
                                      :conditions => ["se_visibile = 1 AND se_home_menu = 0 AND top_menu_id =  ?", @top_menu.id]
    )
    #@topsection_ids = @top_sections.select(:id).uniq
    # Paginate results
    case params[:format]
      when 'xml', 'json'
        @offset, @limit = api_offset_and_limit
      else
        @limit = 5
        @offset= 25
    end

    @issues_count =Issue.count(
        :include => [:section => :top_section],
        :conditions => ["#{TopSection.table_name}.top_menu_id IN (?)", @topsection_ids]
    )

    @issues_pages = Paginator.new self, @issues_count, @limit, params['page']
    @issues = Issue.find(:all,
                         :include => [:section => :top_section],
                         :order => 'updated_on DESC',
                         :conditions => ["se_visible_web = 1 AND #{TopSection.table_name}.se_visibile =1 AND #{TopSection.table_name}.se_home_menu = 0 AND #{TopSection.table_name}.top_menu_id = ?", @top_menu.id],
                         :limit => @issues_pages.items_per_page,
                         :offset => @issues_pages.current.offset)

    respond_to do |format|
      format.html {
        render :layout => !request.xhr?
      }
      format.api
    end
  end

  #dal menu sezione si accede all'insieme degli articoli riferiti alla sezione
  #map.sezione_page '/editorial/:topmenu_key/sezione/:topsection_id'
  #link_to sezione_page_url
  def top_sezione
    @base_url = params[:pages] #request.path
    @key_url = params[:topmenu_key]
                               # @topsection_id = params[:topsection_id]
    @topsection_key = params[:topsection_key]
    @topsection = TopSection.find(:first, :conditions => ["top_sections.`key` = ?", @topsection_key])
                               #flash[:notice] = l(:notice_missing_parameters) + " -->  @section_id="+ @topsection.id.to_s   + @topsection_key
                               # if @topsection_id.nil?
                               #         flash[:notice] = l(:notice_missing_parameters) + " --> 1 @key_url=" + @key_url + ", @topsection_id=" + @topsection_id.to_s
                               #         redirect_to :action => 'home'
                               #         return
                               #     end
    if @topsection.nil?
      flash[:notice] = l(:notice_missing_parameters) + " --> 3 @section_id="+ @topsection.id.to_s
      redirect_to :action => 'home'
      return
    end
                               # Paginate results
    case params[:format]
      when 'xml', 'json'
        @offset, @limit = api_offset_and_limit
      else
        @limit = 5
        @offset= 25
    end
                               # --> sandro debug zona
                               # @top_menu = TopMenu.find(:first, :conditions => ["`key`=?", @key_url])
                               # @topsection_ids = TopSection.find(:all,
                               #                                   :select => 'distinct id',
                               #                                   :conditions => ["top_menu_id =  ?", @top_menu.id]
                               # )
                               # -->
    @issues_count =Issue.count(
        :include => [:section => :top_section],
        :conditions => ["#{TopSection.table_name}.id = ?", @topsection.id]
    )
    @issues_pages = Paginator.new self, @issues_count, @limit, params['page']
    @issues = Issue.find(:all,
                         :include => [:section => :top_section],
                         :order => 'created_on DESC',
                         :conditions => ["se_visible_web = 1 AND is_private = 0 AND se_visible_newsletter = 1 AND  #{TopSection.table_name}.id = :sid", {:sid => @topsection.id}],
                         :limit => @issues_pages.items_per_page,
                         :offset => @issues_pages.current.offset)

    respond_to do |format|
      format.html {
        render :layout => !request.xhr?
      }
      format.api
    end
    #MariaCristina Condizione per VisibileWeb, ordinamento per
    #@issues = Issue.find(:all, :conditions => ["section_id =  ?", @id], :limit => 100)
    #@issues = Issue.all_by_sezione_fs(@id)
  end
  # -----------------  ARTICOLO  (inizio)   ------------------
  def articolo
    #singolo articolo
    @id = params[:article_id].to_i
    @articolo= Issue.find(@id)
    @section_id = @articolo.section_id
  end

=begin
non usata?
  def articoli
     @issues2 = Issue.latest_fs
  end
=end

  # -----------------  ARTICOLO  (fine)   ------------------
  # -----------------  EDIZIONI /NEWSLETTER  (inizio)  ------------------
  def edizioni
    @projects = Project.all_fs
  end

  def edizione
    @id = params[:id].to_i
    @project = Project.find_public(@id)
    @issues = @project.issues.all(:order => "#{Section.table_name}.top_section_id DESC", :include => [:section => :top_section])
    @block_projects = Project.latest_fs
  end
  def edizione_newsletter
    #Newsletter  grafica della newsletter
    @id = params[:id].to_i
    @project = Project.find_public(@id)
    @art = @project.issues.all(:order => "#{Section.table_name}.top_section_id DESC", :include => [:section => :top_section])
    @prj= Project.find_by_id params[:id].to_i
  end
  def edizione_smtp
    #Newsletter spedita direttamente via smtp VIEW solo per test
    @id = params[:id].to_i
    @project = Project.find_public(@id)
    @art = @project.issues.all(:order => "#{Section.table_name}.top_section_id DESC", :include => [:section => :top_section])
    @news = @project.newsletter_smtp(User.current)
    @prj= Project.find_by_id params[:id].to_i
  end
  # -----------------  EDIZIONI /NEWSLETTER  (fine)  ------------------
  # -----------------  CONVEGNI / EVENTI  (inizio)   ------------------
  def convegni


  end
  # -----------------  CONVEGNI / EVENTI  (inizio)   ------------------

 # -----------------       QUESITI    (inizio)        ------------------

  def quesiti
  end

  def quesito_full
    @id = params[:id].to_i
    @quesito= New.find(@id)
    @editorial_id = @quesito.project_id
  end

#domthu permission :front_end_quesito, :editorial => :quesito_nuovo, :require => :loggedin
#add permission to control permission action
#Admin e power_user sono definiti da campi della tabella User
#RUOLI
#MANAGER --> ok
#REDATTORE --> ok
#ABBONATO --> ok
#Anomimo --> KAPPAO
#GUEST --> KAPPAO
#SCADUTI --> KAPPAO
#ARCHIVIATI --> KAPPAO
  def quesito_new
    if User.current = nil
      redirect_to(login_url) && return
    end
    #DO SOME USRE STUFF HERE

  end
  # -----------------       QUESITI    (fine)        ------------------
  def contact
  end

  def help
  end

  def banners
    @xbanner = GroupBanner.find(:all, :order => 'priorita DESC', :conditions => ["se_visible = 1"])
  end

#{"all_words"=>"1",
# "submit"=>"Invia",
# "projects"=>"1",
# "q"=>"quesit",
# "issues"=>"1",
# "titles_only"=>"",
# "news"=>"1"}
  def ricerca
    @question = params[:q] || ""
    @question.strip!
    @all_words = params[:all_words] ? params[:all_words].present? : true
    @titles_only = params[:titles_only] ? params[:titles_only].present? : false

    projects_to_search =
#      case params[:scope]
#      when 'all'
#        nil
#      when 'my_projects'
#        User.current.memberships.collect(&:project)
#      when 'subprojects'
#        @project ? (@project.self_and_descendants.active) : nil
#      else
#        @project
#      end

        offset = nil
    begin
      ; offset = params[:offset].to_time if params[:offset];
    rescue;
    end

    # quick jump to an issue
    if @question.match(/^#?(\d+)$/) && Issue.visible.find_by_id($1.to_i)
      redirect_to :controller => "editorial", :action => "articolo", :id => $1
      return
    end

    #issues news documents changesets wiki_pages messages projects
    @object_types = Redmine::Search.available_search_types_fs.dup
    if projects_to_search.is_a? Project
      # don't search projects
      @object_types.delete('projects')
      # only show what the user is allowed to view
      #@object_types = @object_types.select {|o| User.current.allowed_to?("view_#{o}".to_sym, projects_to_search)}
    end

    @scope = @object_types.select { |t| params[t] }
    @scope = @object_types if @scope.empty?

    # extract tokens from the question
    # eg. hello "bye bye" => ["hello", "bye bye"]
    @tokens = @question.scan(%r{((\s|^)"[\s\w]+"(\s|$)|\S+)}).collect { |m| m.first.gsub(%r{(^\s*"\s*|\s*"\s*$)}, '') }
    # tokens must be at least 2 characters long
    @tokens = @tokens.uniq.select { |w| w.length > 1 }

    if !@tokens.empty?
      # no more than 5 tokens to search for
      @tokens.slice! 5..-1 if @tokens.size > 5

      @results = []
      @results_by_type = Hash.new { |h, k| h[k] = 0 }

      limit = 10
      @scope.each do |s|
        r, c = s.singularize.camelcase.constantize.search(@tokens, projects_to_search, :all_words => @all_words, :titles_only => @titles_only, :limit => (limit+1), :offset => offset, :before => params[:previous].nil?)
        @results += r
        @results_by_type[s] += c
      end

      #You have a nil object when you didn't expect it!
      #@results = @results.sort! {|a,b| b.event_datetime <=> a.event_datetime}
      @results = @results.compact.sort { |a, b| b.event_datetime <=> a.event_datetime }

      if params[:previous].nil?
        @pagination_previous_date = @results[0].event_datetime if offset && @results[0]
        if @results.size > limit
          @pagination_next_date = @results[limit-1].event_datetime
          @results = @results[0, limit]
        end
      else
        @pagination_next_date = @results[-1].event_datetime if offset && @results[-1]
        if @results.size > limit
          @pagination_previous_date = @results[-(limit)].event_datetime
          @results = @results[-(limit), limit]
        end
      end
    else
      @question = ""
    end
    render :layout => false if request.xhr?
  end

  def unauthorized
  end

#def register  --> Move to Account
#end
#def login  --> Move to Account
#end

  private
  def find_optional_project
    return true unless params[:id]
    @project = Project.find(params[:id])
    check_project_privacy
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def correct_user
    reroute_log() unless User.current.logged?
    #reroute_auth() unless User.current.isfee?(params[:id])
  end

  def reroute_log()
    flash[:notice] = "Per accedere al contenuto devi essere authentificato. Fai il login per favore..."
    redirect_to(signin_path)
  end

  def enabled_user
    reroute_auth() unless User.current.isfee?(params[:id])
  end

  def reroute_auth()
    flash[:notice] = "Per accedere al contenuto devi avere un abbonamento in corso..."
    flash[:error] = "Abbonamento non valido (utente)..."
    redirect_to(unauthorized_path)
  end

end

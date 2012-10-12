class EditorialController < ApplicationController
  layout 'editorial'
  #before_filter :require_admin
  helper :sort
  include SortHelper	
  include FeesHelper  #ROLE_XXX

  before_filter :find_optional_project, :only => [:ricerca]
  helper :messages
  include MessagesHelper

  caches_action :robots

  def home
#    @last_editorial = Project.visible.find(:all, :order => 'lft')
#    @p = Project.find(:first, :order => 'created_on DESC')
#    @projects = Project.all.compact.uniq
#    @link_project = Project.find_by_identifier($1) || Project.find_by_name($1)
    @projects = Project.latest_fs
    @issues = Issue.latest_fs
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
    @id = params[:id].to_i
    if @id.nil?
      flash[:notice] = l(:notice_missing_parameters)
      redirect_to :action => 'home'
    else
      @top_menu = TopMenu.find(@id)
      @top_sections = TopSection.find(:all, :conditions => ["top_menu_id =  ?", @id])
    
    end
  end
  
  def contact
  end

  def help
  end

  def about
  end

  #dal menu sezione si accede all'insieme degli articoli riferiti alla sezione
  def sezione
    @id = params[:id].to_i
    if @id.nil?
      flash[:notice] = l(:notice_missing_parameters)
      redirect_to :action => 'home'
    else
      @top_section = TopSection.find(@id)
      #@issues = @top_section.sections.issues
      #restituisce un ActiveRecord::Relation.
      #undefined method `issues' for #<Class:0xb6795b9c>
      @test = @top_section.sections.class
      @issues = @top_section.issues
      
      @sections = @top_section.sections
      @issues2 = []
      for section in @sections
        @issues2 << section.issues
      end 
      
      @sottosezione = Section.find(@id)
      @sezione = @sottosezione.nil? ? TopSection.find(:first, :include => [ :section ], :conditions => ["#{Section.table_name}.id = :secid", {:secid => @id }]) : @sottosezione.top_section

      #MariaCristina Condizione per VisibileWeb, ordinamento per 
      #@issues = Issue.find(:all, :conditions => ["section_id =  ?", @id], :limit => 100)  
      #@issues = Issue.all_by_sezione_fs(@id)
    end 
  end

  def edizioni
    @projects = Project.all_fs
  end

  def edizione
    #Newsletter
    #project --> 'e000259'
    #@id = params[:id] # attenzione è una stringa .to_i
    #project.id --> 23
    @id = params[:id].to_i
    @project = Project.find_public(@id)
  end

  def articoli

    @issues = Issue.latest_fs
    #@sezione = @sottosezione.nil? ? TopSection.find(:first, :include => [ :section ], :conditions => ["#{Section.table_name}.id = :secid", {:secid => @id }]) : @sottosezione.top_section
  end

  def articolo
    @id = params[:id].to_i
    @comune = Comune.find(params[:id])
  end

  def quesiti
  end

  def quesito
    @id = params[:id].to_i
    @comune = Comune.find(params[:id])
  end

#domthu permission :front_end_quesito, :editorial => :poniquesito, :require => :loggedin
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
  def poniquesito
    if not User.current.allowed_to?(:front_end_quesito, nil, :global => true)
      redirect_to(login_url) && return
    end
    #DO SOME USRE STUFF HERE
    
  end

  #def register
  #end
  #def login
  #end

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
    begin; offset = params[:offset].to_time if params[:offset]; rescue; end

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

    @scope = @object_types.select {|t| params[t]}
    @scope = @object_types if @scope.empty?

    # extract tokens from the question
    # eg. hello "bye bye" => ["hello", "bye bye"]
    @tokens = @question.scan(%r{((\s|^)"[\s\w]+"(\s|$)|\S+)}).collect {|m| m.first.gsub(%r{(^\s*"\s*|\s*"\s*$)}, '')}
    # tokens must be at least 2 characters long
    @tokens = @tokens.uniq.select {|w| w.length > 1 }

    if !@tokens.empty?
      # no more than 5 tokens to search for
      @tokens.slice! 5..-1 if @tokens.size > 5

      @results = []
      @results_by_type = Hash.new {|h,k| h[k] = 0}

      limit = 10
      @scope.each do |s|
        r, c = s.singularize.camelcase.constantize.search(@tokens, projects_to_search,
          :all_words => @all_words,
          :titles_only => @titles_only,
          :limit => (limit+1),
          :offset => offset,
          :before => params[:previous].nil?)
        @results += r
        @results_by_type[s] += c
      end
      
      #You have a nil object when you didn't expect it!
      #@results = @results.sort! {|a,b| b.event_datetime <=> a.event_datetime}
      @results = @results.compact.sort{|a,b| b.event_datetime <=> a.event_datetime}
      
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

private
  def find_optional_project
    return true unless params[:id]
    @project = Project.find(params[:id])
    check_project_privacy
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end

class EditorialController < ApplicationController
  layout 'editorial'
  #before_filter :require_admin
  helper :sort
  include SortHelper
  include FeesHelper #ROLE_XXX  CONVEGNI_XXX QUESITO_XXX

  before_filter :find_optional_project, :only => [:ricerca]
  before_filter :correct_user, :only => [:articolo, :quesito_full]
  before_filter :enabled_user, :only => [:articolo, :quesito_full]
  before_filter :find_quesito_fs, :only => [:quesito_destroy, :quesito_edit, :quesito_show]

  helper :messages
  include MessagesHelper

  caches_action :robots

  #HOME > TOP_MENU > TOP_SECTION > SECTION > ARTICOLO
  def home
    @xbanner = GroupBanner.find(:all, :order => 'priorita DESC', :conditions => ["se_visibile = 1"])
    @base_url = params[:pages]
    @block_projects = Project.latest_fs
    @projects = Project.latest_fs
    case params[:format]
      when 'xml', 'json'
        @offset, @limit = api_offset_and_limit
      else
        @limit = 5
        @offset= 25
    end
    @top_menu = TopMenu.find(:first, :conditions => 'id =1')
    @topsection_ids = TopSection.find(:all,
                                      :select => 'distinct id',
                                      :conditions => ["top_menu_id =  ?", @top_menu.id]
    )
    @issues_count = Issue.all_public_fs.count
    @issues_pages = Paginator.new self, @issues_count, @limit, params['page']
    @issues = Issue.all_public_fs.all(
        :limit => @issues_pages.items_per_page,
        :offset => @issues_pages.current.offset)
    #Issue.visible.on_active_project.watched_by(user.id).recently_updated.with_limit(10)

    respond_to do |format|
      format.html {
        render :layout => !request.xhr?
      }
      format.api

    end
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

    @issues_count =Issue.all_public_fs.with_filter("#{TopSection.table_name}.se_home_menu = 0 AND #{TopSection.table_name}.top_menu_id = " + @top_menu.id.to_s).count()

    @issues_pages = Paginator.new self, @issues_count, @limit, params['page']
    @issues = Issue.all_public_fs.with_filter("#{TopSection.table_name}.se_home_menu = 0 AND #{TopSection.table_name}.top_menu_id = " + @top_menu.id.to_s).all(
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
    @issues_count =Issue.all_public_fs.with_filter("#{TopSection.table_name}.id = " + @topsection.id.to_s).count()
    @issues_pages = Paginator.new self, @issues_count, @limit, params['page']
                               #Kapao riompe la paginazione @issues = Issue.all_public_fs.with_filter("#{TopSection.table_name}.id = " + @topsection.id.to_s).with_limit(@issues_pages.items_per_page).with_offset(@issues_pages.current.offset)
    @issues = Issue.all_public_fs.with_filter("#{TopSection.table_name}.id = " + @topsection.id.to_s).all(
        :limit => @issues_pages.items_per_page,
        :offset => @issues_pages.current.offset)

    respond_to do |format|
      format.html {
        render :layout => !request.xhr?
      }
      format.api
    end
  end

  # -----------------  ARTICOLO  (inizio)   ------------------
  def articolo
    #singolo articolo
    @id = params[:article_id].to_i
    @articolo= Issue.all_public_fs.find(@id )
    @section_id = @articolo.section_id
    if @articolo.news_id
    @quesito = News.all_quesiti_fs.find_by_id(@articolo.news_id)
    end

  end



  # -----------------  ARTICOLO  (fine)   ------------------
  # -----------------  EDIZIONI /NEWSLETTER  (inizio)  ------------------
  def edizioni
    @projects = Project.all_fs
  end

  def edizione
    @id = params[:id].to_i
    if @id.nil?
      flash[:notice] = l(:notice_not_authorized)
      return redirect_to({:action => 'home'})
    end
    @project = Project.all_public_fs.find_public(@id)
    if @project.nil?
      flash[:notice] = l(:notice_not_authorized)
      return redirect_to({:action => 'home'})
    else
      @issues = @project.issues.all(:order => "#{Section.table_name}.top_section_id DESC", :include => [:section => :top_section])
      @block_projects = Project.latest_fs
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def edizione_newsletter
    #Newsletter  grafica della newsletter
    @id = params[:id].to_i
    @project = Project.all_public_fs.find_public(@id)
    @art = @project.issues.all(:order => "#{Section.table_name}.top_section_id DESC", :include => [:section => :top_section])
    @prj= Project.all_public_fs.find_by_id params[:id].to_i
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
    # Paginate results
    case params[:format]
      when 'xml', 'json'
        @offset, @limit = api_offset_and_limit
      else
        @limit = 5
        @offset= 25
    end

#    @topsection = TopSection.find(:first, :conditions => ["top_sections.id = ?", FeeConst::CONVEGNO_TOP_SECTION_ID])
#    @issues_count =Issue.all.count(
#        :conditions => ["#{TopSection.table_name}.id = ?", FeeConst::CONVEGNO_TOP_SECTION_ID]
#    )
#    @issues_pages = Paginator.new self, @issues_count, @limit, params['page']
#    @convegni = Issue.all(
#       :conditions => [" #{TopSection.table_name}.id = ?", FeeConst::CONVEGNO_TOP_SECTION_ID],
#       :limit => @issues_pages.items_per_page,
#       :offset => @issues_pages.current.offset)


    @topsection = TopSection.find_convegno(:first)
    @issues_count =Issue.all_public_fs.solo_convegni.count()
    @issues_pages = Paginator.new self, @issues_count, @limit, params['page']
    @convegni = Issue.all_public_fs.solo_convegni.all(
        :limit => @issues_pages.items_per_page,
        :offset => @issues_pages.current.offset)

    respond_to do |format|
      format.html {
        render :layout => !request.xhr?
      }
      format.api
    end

  end

  def evento_prenotazione
    @reservation_new = Reservation.new(:user_id => User.current.id, :issue_id => params[:issue_id], :num_persone => params[:num_persone], :msg => params[:msg])

    redirect_back_or_default({:action => 'evento', :id => params[:id].to_i})

  end

  def evento_prenotazione_delete
    @reservation = Reservation.find(params[:id])
    @reservation.destroy
    redirect_back_or_default eventi_url
  end

  def evento
    #singolo articolo
    @id = params[:id].to_i
    @backurl = request.url
    @convegno= Issue.find(@id)

    @rcount = Reservation.count(:conditions => "issue_id = #{@id} AND user_id = #{User.current.id}")
    if @rcount <= 0
      #@reservation_new = Reservation.new(:user_id => User.current.id, :issue_id => params[:issue_id],:num_persone => params[:num_persone],:msg => params[:msg])
      @reservation_new = Reservation.new
    else
      @reservation =Reservation.find(:first, :conditions => "issue_id = #{@id} AND user_id = #{User.current.id}")
    end
    @conv_prossimo = Issue.all_public_fs.solo_convegni.first(
        :order => 'due_date ASC',
        :conditions => "#{Issue.table_name}.due_date >=' #{DateTime.now.to_date}'")

    if @conv_prossimo.nil?
      @conv_futuri
    else
      @cid = @conv_prossimo.id
      @conv_futuri = Issue.all_public_fs.solo_convegni.all(
          :order => 'due_date ASC',
          :conditions => " issues.due_date >' #{DateTime.now.to_date}' AND  issues.id <> #{@cid.to_i}")
    end
  end

  def eventi
    @backurl = request.url
    #solo per test copia di convegno
    @conv_passati = Issue.all_public_fs.solo_convegni.all(
        :order => 'due_date DESC',
        :conditions => "due_date <' #{DateTime.now.to_date}'")

    @conv_prossimo = Issue.all_public_fs.solo_convegni.first(
        :order => 'due_date ASC',
        :conditions => "#{Issue.table_name}.due_date >=' #{DateTime.now.to_date}'")

    if @conv_prossimo.nil?
      @conv_futuri
    else
      @cid = @conv_prossimo.id #  = if @conv_prossimo.id.nil? ? 0 : @conv_prossimo.id ; end
      @conv_futuri = Issue.all_public_fs.solo_convegni.all(
          :order => 'due_date ASC',
          :conditions => " issues.due_date >' #{DateTime.now.to_date}' AND  issues.id <> #{@cid.to_i}")
                               #reservations
      @reservation_new =Reservation.new
      @rcount = Reservation.count(:conditions => "issue_id = #{@cid} AND user_id = #{User.current.id}")
      @reservation =Reservation.find(:first, :conditions => "issue_id = #{@cid} AND user_id = #{User.current.id}")
      @convegno= Issue.find(@cid)
    end
  end


  # -----------------  CONVEGNI / EVENTI  (fine)   ------------------

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

  # -----------------       QUESITI    (inizio)        ------------------

  #Lista di tutti quesiti (ISSUE) che hanno avvuto una risposta positiva e pubblicata
  def quesiti
    @quesiti_art = Issue.quesiti
  end

  #Lista dei quesiti (NEWS) dell'utente
  def quesiti_my
    # if User.current = nil
    #   redirect_to(login_url) && return
    # end
    @quesiti_news = User.current.my_quesiti
    #if User.current = nil
    #   redirect_to(login_url) && return
    # end
  end

  def quesito_new
  end

  #POST del quesito_new
  def quesito_create
    @project = Project.find_by_id(FeeConst::QUESITO_ID)
    if @project.nil?
      Project.exists_row_quesiti
      @project = Project.find_by_id(FeeConst::QUESITO_ID)
    end
    @news = News.new(:project => @project, :author => User.current)
    @news.safe_attributes = params[:quesito]
    @news.title = @news.quesito_new_default_title(User.current)
    @news.status_id = FeeConst::QUESITO_STATUS_WAIT
    @news.comments_count = 0
    if request.post?
      if @news.save
        # flash[:notice] = l(:notice_successful_create)
        flash[:notice] = fading_flash_message("I suo quesito è stato registrato grazie.", 7)
        redirect_to :controller => 'editorial', :action => 'quesiti_my' #, :id => @news
        #redirect_to :controller => 'news', :action => 'index', :project_id => @project
      else
        flash.now[:notice] = 'Bah... qualcosa è andato storto!'
      end
    end
  end

  #Il dato @quesito_news viene caricato dentro il before_filter
  def quesito_edit
    @news.title = @news.quesito_new_default_title(User.current)
    @quesito_news.summary = params[:summary]
    @quesito_news.description = params[:description]
    if request.post?
      if @quesito_news.save
        flash[:notice] = fading_flash_message(l(:notice_successful_update), 7)
      else
        flash[:notice] = 'qualcosa è andato storto!'
      end
    end
    redirect_to :controller => 'editorial', :action => 'quesito_show', :id => @quesito_news
  end

  #Il dato @quesito_news viene caricato dentro il before_filter
  def quesito_destroy
    #verificare che l'utente sia un admin o un se stesso
    if @quesito_news.author == User.current || User.current.admin?
      @quesito_news.destroy #@quesito_news = News.destroy(params[:id])
      flash[:notice] = fading_flash_message("Il suo quesito è stato rimosso.", 7)
      # flash[:notice] =  'quesito rimosso!'
    else
      flash[:error] = fading_flash_message("Solo l'utente che ha creato il quesito può eliminarlo", 15)
    end
    redirect_to :controller => 'editorial', :action => 'quesiti_my'
  end

  #Show del singolo quesito. Attenzione l'id passato è quello della NEWS
  # Viene passato un id che corrisponde alla news = domanda fatta dal cliente
  #REQUEST
  #Il dato @quesito_news viene caricato dentro il before_filter
  def quesito_show
    #1 news sola
    @quesito_news = News.find(@id) # unless !@id.nil?
    @quesito_news_stato = @quesito_news.quesito_status_fs_text
    @quesito_news_stato_num = @quesito_news.quesito_status_fs_number
                                   #lista issues-articoli [0..n]  @quesiti_art.empty? @quesiti_art.count

                                   # @quesito_issues = @quesito_news.issues
    @quesito_issues_all_count = @quesito_news.issues.count # testing
    @quesito_issues = @quesito_news.issues.all_public_fs #--> Verificare se funzione pero dovrebbe riportare un array di news e non di issue
    @quesito_issues_count = @quesito_issues.count
  end

  #Show del singolo quesito. Attenzione l'id passato è quello dell'articolo
  # Viene passato un id che corrisponde all'articolo = risposta di un quesito cliente
  #RESPONSE(s)
  def quesiti_all

    case params[:format]
      when 'xml', 'json'
        @offset, @limit = api_offset_and_limit
      else
        @limit = 3
        @offset= 25
    end

    @quesiti_news_count = News.all_public_fs.count
     @quesiti_news_pages = Paginator.new self, @quesiti_news_count, @limit, params['page']
    @quesiti_news = News.all_public_fs(
        :limit => @quesiti_news_pages.items_per_page,
        :offset => @quesiti_news_pages.current.offset)

    respond_to do |format|
      format.html {
        render :layout => !request.xhr?
      }
      format.api
    end

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
    if @question.match(/^#?(\d+)$/) && Issue.visible_fs.find_by_id($1.to_i)
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

  def find_quesito_fs
    @id = params[:id].to_i
    #@quesito_news = News.all_public_fs.find(@id)
    #solo i quesiti di FeeConst::QUESITO_KEY
    # dominiqe questa non va mi blocca la visualizzazione della show la rimuovo temporaneamente
    # @quesito_news = News.all_quesiti_fs.find(@id)
    @quesito_news = News.find(@id)
    #In application_contoller
    check_quesito_privacy_fs
    #rescue ActiveRecord::RecordNotFound
    #  render_404
  end

  def find_optional_project
    return true unless params[:id]
    @project = Project.all_public_fs.find(params[:id])
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

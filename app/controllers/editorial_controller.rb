class EditorialController < ApplicationController
  layout 'editorial' #, :except => [:profilo_new]
                     #before_filter :require_admin
  helper :sort
  include SortHelper
  include FeesHelper #ROLE_XXX  CONVEGNI_XXX QUESITO_XXX

  before_filter :find_optional_project, :only => [:ricerca]
  before_filter :find_articolo, :only => [:articolo] #, :preview_articolo can be not visible]  #recupero articolo status
                     #  #before_filter :get_news, :only => [:news, :articolo_full]  #recupero articolo status
  before_filter :correct_user_article, :only => [:articolo] #LOGGATO O ARTICOLO LIBERO
  before_filter :enabled_user_article, :only => [:articolo] #ABBONATO E ARTICOLO protetto o SECTION protetto
  before_filter :find_user_profile, :only => [:profilo_edit, :profilo_destroy, :profilo_show]
  before_filter :correct_user_profile, :only => [:profilo_edit, :profilo_destroy, :profilo_create] #Admin o se stesso
  before_filter :find_quesito_fs, :only => [:quesito_destroy, :quesito_edit, :quesito_show]
  before_filter :correct_user_quesito, :only => [:quesito_destroy, :quesito_edit] #Admin o se stesso

  helper :messages
  include MessagesHelper
  caches_action :robots
                     #HOME > TOP_MENU > TOP_SECTION > SECTION > ARTICOLO
  def home
    @xbanner = GroupBanner.find(:all, :order => 'priorita DESC', :conditions => ["visibile_web = 1"])
    @base_url = params[:pages]
    @block_projects = Project.latest_fs
    @projects = Project.latest_fs
    case params[:format]
      when 'xml', 'json'
        @offset, @limit = api_offset_and_limit
      else
        #@limit = 5
        #@offset= 25
        @limit = per_page_option_fs
    end
    @top_menu = TopMenu.find(:first, :conditions => 'id =1')
    @topsection_ids = TopSection.find(:all,
                                      :select => 'distinct id',
                                      :conditions => ["top_menu_id =  ?", @top_menu.id]
    )
    @issues_count = Issue.all_public_fs.count
    @issues_pages = Paginator.new self, @issues_count, @limit, params['page']
    @offset ||= @issues_pages.current.offset
    @issues = Issue.all_public_fs.all(
        :limit => @limit,
        :offset => @offset)
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
                                      :conditions => ["se_visibile = 1 AND hidden_menu = 0 AND top_menu_id =  ?", @top_menu.id]
    )
    #@topsection_ids = @top_sections.select(:id).uniq
    # Paginate results
    case params[:format]
      when 'xml', 'json'
        @offset, @limit = api_offset_and_limit
      else
        #@limit = 5
        #@offset= 25
        @limit = per_page_option_fs
    end

    @issues_count =Issue.all_public_fs.with_filter("#{TopSection.table_name}.hidden_menu = 0 AND #{TopSection.table_name}.top_menu_id = " + @top_menu.id.to_s).count()

    @issues_pages = Paginator.new self, @issues_count, @limit, params['page']
    @offset ||= @issues_pages.current.offset
    @issues = Issue.all_public_fs.with_filter("#{TopSection.table_name}.hidden_menu = 0 AND #{TopSection.table_name}.top_menu_id = " + @top_menu.id.to_s).all(
        :limit => @limit,
        :offset => @offset)

    respond_to do |format|
      format.html {
        render :layout => !request.xhr?
      }
      format.api
    end
  end

  def top_sezione
    #inizio box convegni
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
    #fine box convegni

    @base_url = params[:pages] #request.path
    @key_url = params[:topmenu_key]
    # @topsection_id = params[:topsection_id]
    @topsection_key = params[:topsection_key]
    @topsection = TopSection.find(:first, :conditions => ["top_sections.`key` = ?", @topsection_key])
    if @topsection.nil?
      flash[:alert] = :notice_missing_parameters + " --> 3 @section_id="+ @topsection.id.to_s
      redirect_to :action => 'home'
      return
    end
    # Paginate results
    case params[:format]
      when 'xml', 'json'
        @offset, @limit = api_offset_and_limit
      else
        #@limit = 5
        #@offset= 25
        @limit = per_page_option_fs
    end
    @issues_count =Issue.all_public_fs.with_filter("#{TopSection.table_name}.id = " + @topsection.id.to_s).count()
    @issues_pages = Paginator.new self, @issues_count, @limit, params['page']
    #Kapao riompe la paginazione @issues = Issue.all_public_fs.with_filter("#{TopSection.table_name}.id = " + @topsection.id.to_s).with_limit(@issues_pages.items_per_page).with_offset(@issues_pages.current.offset)
    @offset ||= @issues_pages.current.offset
    @issues = Issue.all_public_fs.with_filter("#{TopSection.table_name}.id = " + @topsection.id.to_s).all(
        :limit => @limit,
        :offset => @offset)

    respond_to do |format|
      format.html {
        render :layout => !request.xhr?
      }
      format.api
    end
  end

  # -----------------  ARTICOLO  (inizio)   ------------------
  #La preview puo essere vista anche se non è pubblico il project o l'issue
  def preview_articolo
    @id = params[:article_id].to_i
    #articolo tipo quesito
    _action = "articolo"
    @articolo = Issue.find_by_id(@id)
    if @articolo.is_quesito?
      #Attenzione si vede News e non Issue
      @quesito_news = News.find_by_id(@articolo.news_id)
      other_quesito_datas()
      _action = "quesito_show"
      #articolo tipo convegno
    elsif @articolo.is_convegno?
      @convegno= @articolo
      other_evento_datas()
      _action = "evento"
      #articolo normale
    else
      other_articolo_datas()
    end
    respond_to do |format|
      format.html {
        render :action => _action #, :locals => {:user => @user, :block_name => block}
      }
      format.api
    end

  rescue ActiveRecord::RecordNotFound
    reroute_404("L'articolo cercato non è è stato trovato...")
  end

  #@id e @articolo in find_articolo
  def articolo
    other_articolo_datas()
  end

  # -----------------  ARTICOLO  (fine)   ------------------
  # -----------------  EDIZIONI /NEWSLETTER  (inizio)  ------------------
  def edizioni
    @projects = Project.all_fs
  end

  def edizione
    @id = params[:id].to_i
    if @id.nil?
      flash[:alert] = l(:notice_not_authorized)
      return redirect_to({:action => 'home'})
    end
    @project = Project.all_public_fs.find_public(@id)
    if @project.nil?
      flash[:alert] = l(:notice_not_authorized)
      return redirect_to({:action => 'home'})
    else
      # @issues = @project.issues.all(:include => [:section => :top_section],
      #                     :order => "#{TopSection.table_name}.ordinamento ASC , due_date DESC")
      @issues = @project.issues.all(:order => "#{TopSection.table_name}.ordinamento ASC , #{Issue.table_name}.due_date DESC", :include => [:section => :top_section])
      @block_projects = Project.latest_fs
    end
  rescue ActiveRecord::RecordNotFound
    #reroute_404()
    flash[:error] = l(:project_not_found, :id => @id)
    return redirect_to({:action => 'home'})
  end

  def edizione_newsletter
    #Newsletter  grafica della newsletter
    @id = params[:id].to_i
    @project = Project.all_public_fs.find_public(@id)
    #domthu 20130919 problema di ordinamento
    #NON ok http://37.59.40.44:88/edizione_newsletter/361
    #ex --> @art =@project.issues.all_public_fs_nl_preview
    #coretto http://37.59.40.44:88/edizione/361
    @art =@project.issues.all(:order => "#{TopSection.table_name}.ordinamento ASC , #{Issue.table_name}.due_date DESC", :include => [:section => :top_section])
    @prj= @id.to_i
    @user = User.current
  rescue ActiveRecord::RecordNotFound
    #reroute_404()
    flash[:error] = l(:project_not_found, :id => @id)
    return redirect_to({:action => 'home'})
  end

  # -----------------  EDIZIONI /NEWSLETTER  (fine)  ------------------

  # -----------------  CONVEGNI / EVENTI  (inizio)   ------------------
  def convegni
    # Paginate results
    case params[:format]
      when 'xml', 'json'
        @offset, @limit = api_offset_and_limit
      else
        #@limit = 5
        #@offset= 25
        @limit = per_page_option_fs
    end
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
    if request.post?
      @reservation_new = Reservation.new(:user_id => User.current.id, :issue_id => params[:issue_id], :num_persone => params[:num_persone], :msg => params[:msg])
      @reservation_new.save
    end
    redirect_back_or_default eventi_url

  end

  def evento_prenotazione_delete
    @reservation = Reservation.find(params[:id])
    @reservation.destroy
    redirect_back_or_default eventi_url
  end

  def evento
    #singolo articolo
    @id = params[:id].to_i
    @convegno= Issue.find(@id)
    other_evento_datas()
  rescue ActiveRecord::RecordNotFound
    reroute_404("L'evento cercato non è è stato trovato...")
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
                               # @reservation_new =Res.newervation
      @rcount = Reservation.count(:conditions => "issue_id = #{@cid} AND user_id = #{User.current.id}")
      @reservation =Reservation.find(:first, :conditions => "issue_id = #{@cid} AND user_id = #{User.current.id}")
      @convegno= Issue.find(@cid)
    end
  end

  def send_proposal_meeting
#    puts "------------------User(" + User.current + ")------------------"
#    @user = (User.current && User.current.logged?) ? User.current : User.anonymous
#    puts "++++++++++++++++++User(" + @user.name + ")++++++++++++++++++"
    @msg = params[:body] if params[:body].present?
    #@email = params[:user_mail] if params[:user_mail].present?
    if params[:user_mail].nil? || !params[:user_mail].present? || params[:user_mail].length < 5
      @email = '[no-email]'
    else
      @email = params[:user_mail]
    end
    @stat =''
    @errors = []
    raise_delivery_errors = ActionMailer::Base.raise_delivery_errors
    # Force ActionMailer to raise delivery errors so we can catch it
    ActionMailer::Base.raise_delivery_errors = true
    @stat = 'Invio email non riuscito <br />'
    begin
      #Mailer.deliver_test(User.current)
      #@tmail = Mailer.deliver_proposal_meeting(@email, @user, @msg)
      @tmail = Mailer.deliver_proposal_meeting(@email, User.current, @msg)
      #notice_user_newsletter_email_sent: "Quindicinale %{edizione} del %{date} inviato a %{user}"
      #flash[:notice] = l(:notice_user_newsletter_email_sent)
      @stat = 'Email inviata correttamente <br />'
    rescue Exception => e
      @errors << l(:notice_email_error, e.message)
      @errors << @stat
    end
    ActionMailer::Base.raise_delivery_errors = raise_delivery_errors

    #prototype
    #respond_to do |format|
    #    format.js {
    #      render(:update) {|page|
    #       page.replace_html "user-response", @stat
    #        page.alert(@stat)
    #      }
    #    }
    #end
    #Jquery

    if (!@errors.nil? and @errors.length > 0)
      return render :json => {
          :success => false,
          :errors => @errors
      }
    end

    render :json => {:success => true, :response => @stat}
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

  #Lista dei quesiti (NEWS) dell'utente
  def quesiti_my
    @quesiti_news = User.current.my_quesiti
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
        flash[:success] = "Il suo quesito è stato registrato grazie."
        redirect_to :controller => 'editorial', :action => 'quesiti_my' #, :id => @news
      else
        flash[:error] = "Non ho potuto registrare il quesito... qualcosa è andato storto"
      end
    end
  end

  #Il dato @quesito_news viene caricato dentro il before_filter
  def quesito_edit
    #@news.title = @news.quesito_new_default_title(User.current)
    @quesito_news.summary = params[:summary]
    @quesito_news.description = params[:description]
    if request.post?
      if @quesito_news.save
        flash[:success] = l(:notice_successful_update)
      else
        flash[:error] = 'non ho potuto aggiornare ... qualcosa è andato storto!'
      end
    end
    redirect_to :controller => 'editorial', :action => 'quesito_show', :id => @quesito_news
  end

  #Il dato @quesito_news viene caricato dentro il before_filter
  def quesito_destroy
    if @quesito_news.author == User.current || User.current.admin?
      @quesito_news.destroy
      flash[:notice] = "Quesito rimosso!"
    else
      flash[:error] = "Solo l'utente che ha creato il quesito può eliminarlo"
    end
    redirect_to :controller => 'editorial', :action => 'quesiti_my'
  end

  #Show del singolo quesito. Attenzione l'id passato è quello della NEWS
  # Viene passato un id che corrisponde alla news = domanda fatta dal cliente
  #REQUEST
  #Il dato @quesito_news viene caricato dentro il before_filter
  def quesito_show
    @id = params[:id]
    #1 news sola
    @quesito_news = News.all_quesiti_fs.find(@id)
    other_quesito_datas()
  rescue ActiveRecord::RecordNotFound
    reroute_404("Il quesito cercato non è è stato trovato...")
  end

  #Show del singolo quesito. Attenzione l'id passato è quello dell'articolo
  # Viene passato un id che corrisponde all'articolo = risposta di un quesito cliente
  #RESPONSE(s)
  def quesiti_all
    case params[:format]
      when 'xml', 'json'
        @offset, @limit = api_offset_and_limit
      else
        #@limit = 5
        #@offset= 25
        @limit = per_page_option_fs
    end

    @quesiti_news_count = News.all_public_fs.count
    @quesiti_news_pages = Paginator.new self, @quesiti_news_count, @limit, params['page']
    @quesiti_news = News.all_public_fs.all(
        :limit => @quesiti_news_pages.items_per_page,
        :offset => @quesiti_news_pages.current.offset)
    respond_to do |format|
      format.html {
        render :layout => !request.xhr?
      }
      format.api
    end
    #@issues = @quesiti_news.issues.all_public_fs
    #@ic = issues.count
  end

# -----------------       QUESITI    (fine)        ------------------
# -----------------    CHI SIAMO    (inizio) [menu item] ------------------

  def profili_all
    @users =User.users_profiles_all.who_without_profile
    @has_profile = UserProfile.user_has_profile?(@users)
    @collaboratori = UserProfile.users_profiles_all.collaboratori
    @responsabili = UserProfile.users_profiles_all.responsabili
    @direttori = UserProfile.users_profiles_all.direttori
    @profiles_count = UserProfile.users_profiles_all.count
    if   @profiles_count > 0
      @profiles = UserProfile.users_profiles_all
    end
  end

  def profilo_show
    if @user_profile.nil?
      flash[:alert] = "Profilo non trovato."
    end
    @profiles_hidden = UserProfile.users_profiles_all.invisibili
  end

  def profilo_edit
    if request.post?
      if @user_profile.update_attributes(:user_id => params[:user_id], :display_in => params[:display_in], :fs_qualifica => params[:fs_qualifica], :fs_tel => params[:fs_tel], :fs_fax => params[:fs_fax], :use_gravatar => params[:use_gravatar], :fs_skype => params[:fs_skype], :fs_mail => params[:fs_mail], :external_url => params[:external_url], :titoli => params[:titoli], :curriculum => params[:curriculum])
        if !params[:photo].nil?
          @user_profile.update_attributes(:photo => params[:photo])
        end
        flash[:success] = "il tuo profilo è stato aggiornato."
      else
        flash[:error] = 'non ho potuto aggiornare ... qualcosa è andato storto!'
      end
      redirect_to :action => 'profilo_show', :id => @user_profile
      return
    end
    # render :layout => "editorial_edit"
  end

  def profilo_new
    @uid= params[:id]
    @this_user = User.find_by_id(@uid)
    if request.post?
      @user_profile = UserProfile.new(:user_id => params[:user_id], :display_in => params[:display_in], :fs_qualifica => params[:fs_qualifica], :fs_tel => params[:fs_tel], :fs_fax => params[:fs_fax], :use_gravatar => params[:use_gravatar], :fs_skype => params[:fs_skype], :fs_mail => params[:fs_mail], :external_url => params[:external_url], :titoli => params[:titoli], :curriculum => params[:curriculum])
      if @user_profile.save
        if !params[:photo].nil?
          @user_profile.update_attributes(:photo => params[:photo])
        end
        flash[:success] = "il tuo profilo è stato creato."
      else
        flash[:error] = 'non ho potuto creare ... qualcosa è andato storto!'
      end
      redirect_to :action => 'profilo_show', :id => @user_profile
      return
    end
  end


# sandro sotto  -- per non usare i metodi di default in caso si voglia utilizzare i default in redmine
  def profilo_create
    @user_profile = UserProfile.new(params[:user_profile])
    if request.post?
      if @user_profile.save
        flash[:success] = l(:notice_successful_create)
        redirect_to(profile_show_path(@user_profile.id))
      else
        flash[:error] = 'non ho potuto creare ... qualcosa è andato storto!'
      end
    end
  end

  def profilo_destroy
    @user_profile.destroy
    flash[:notice] = "il tuo profilo è stato rimosso."
    respond_to do |format|
      format.html { redirect_to(profiles_all_url) }
      format.xml { head :ok }
    end
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
    #render :layout => false if request.xhr?
  end

  def unauthorized
  end

#def register  --> Move to Account
#end
#def login  --> Move to Account
#end

  private

  def find_user_profile
    @id = params[:id].to_i
    @user_profile = UserProfile.find_by_id(@id)
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "il profilo non è stato trovato."
    return reroute_404()
  end

  def correct_user_profile
    return reroute_log('correct_user_profile') unless (User.current.admin? || User.current.ismanager? || User.current == @user_profile.user)
  end

  def find_quesito_fs
    @id = params[:id].to_i
    #@quesito_news = News.all_public_fs.find(@id)
    #solo i quesiti di FeeConst::QUESITO_KEY
    # dominiqe questa non va mi blocca la visualizzazione della show la rimuovo temporaneamente
    # @quesito_news = News.all_quesiti_fs.find(@id)
    @quesito_news = News.find(@id)
    #In application_contoller
    check_quesito_privacy_fs
  rescue ActiveRecord::RecordNotFound
    reroute_404()
  end

  def correct_user_quesito
    return reroute_log('correct_user_quesito') unless (User.current.admin? || User.current.ismanager? || User.current == @quesito_news.author)
  end

  def find_optional_project
    return true unless params[:id]
    @project = Project.all_public_fs.find(params[:id])
    check_project_privacy
  rescue ActiveRecord::RecordNotFound
    reroute_404()
  end

  def find_articolo
    return reroute_log('find_articolo') unless !params[:article_id].nil?
    @id = params[:article_id].to_i
    @articolo= Issue.all_public_fs_nl_preview.find(@id)
  rescue ActiveRecord::RecordNotFound
    flash[:error] = "Il contenuto cercato è stato rimosso..."
    redirect_to(:back)
  end

  def reroute_404(_message = nil)
    #flash[:notice] = "Per accedere al contenuto devi essere authentificato. Fai il login per favore..."
    flash[:alert] = "Problemi incontrati nel recupero dei dati..."
    return render_404_fs({:message => _message}) unless _message.nil?
    render_404_fs
    #render_404
  end

  def reroute_log(who)
    send_notice("Per accedere al contenuto devi essere autenticato")
    send_notice("Fai il login per favore... Se non hai abbonamento, registrati ora!")
    #redirect_to(signin_path)
    redirect_to(page_abbonamento_path)
  end

  #definisce se l'utente è loggato o no, se no verifica che l'articolo è pubblico
  def correct_user_article
    if (!User.current.logged? && (@articolo.se_protetto || !@articolo.se_visible_web))
      return reroute_log('correct_user_article')
    end
    #reroute_log('correct_user_article') unless User.current.logged?
  end

  #
  def enabled_user_article
    if @articolo.se_protetto || @articolo.section.protetto
      #controllo della scadenza per aggiornare il ruolo
      User.current.control_state
      #controllo del ruolo
      if !User.current.canread?(@articolo)
        if User.current.isarchivied?
          reroute_auth("Per accedere deve abbonarti di nuovo")
        elsif User.current.isexpired?
          reroute_auth("Il tuo abbonamento è scaduto. Per vedere di nuovo gli articoli protetti devi fare il rinovo")
        elsif User.current.isregistered?
          reroute_auth("Durante il periodo di prova solo gli abbonati regolari possono vedere i contenuti protetti. Abbonati anche tu!")
        else
          reroute_auth("Gli articoli protetti sono riservati ed accessibile solo ai utenti abbonati")
        end
      end
    end
  end

  def reroute_auth(msg)
    if msg
      flash[:notice] = msg
    else
      flash[:notice] = "Per accedere devi avere un abbonamento valido..."
    end
    #redirect_to(my_profile_edit_path)
    redirect_to(my_profile_show_path)
  end

  #privato. Usato sia per articolo che preview (anche se non pubblico il project ed issue)
  def other_articolo_datas()
    @attachements = @articolo.attachments

    #singolo articolo
    @section_id = @articolo.section_id
    @icount = Issue.all_public_fs.with_filter("#{Section.table_name}.id = " + @section_id.to_s).count()
    if @icount > 3
      @artsimilar = Issue.all_public_fs.with_filter("#{Section.table_name}.id = " + @section_id.to_s).all(
          :limit => 10)
    else
      @artsimilar = Issue.all_public_fs.with_filter("#{TopSection.table_name}.id = " + @articolo.section.top_section.id.to_s).all(
          :limit => 10)
    end

    if @articolo.news_id
      @quesito = News.all_quesiti_fs.find_by_id(@articolo.news_id)
    end

  end

  #privato. Usato sia per quesito_show che preview (anche se non pubblico il project ed issue)
  def other_quesito_datas()
    @quesito_news_stato = @quesito_news.quesito_status_fs_text
    @quesito_news_stato_num = @quesito_news.quesito_status_fs_number
    #lista issues-articoli [0..n]  @quesiti_art.empty? @quesiti_art.count

    # @quesito_issues = @quesito_news.issues
    @quesito_issues_all_count = @quesito_news.issues.count # testing
    @quesito_issues = @quesito_news.issues.all_public_fs #--> Verificare se funzione pero dovrebbe riportare un array di news e non di issue
    @quesito_issues_count = @quesito_issues.count
  end

  #privato. Usato sia per evento che preview (anche se non pubblico il project ed issue)
  def other_evento_datas()
    @backurl = request.url

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

end

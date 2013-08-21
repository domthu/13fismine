class NewslettersController < ApplicationController
  layout 'admin'

  before_filter :require_admin
  before_filter :find_project, :only => [ :invii ]
  before_filter :find_newsletter, :only => [ :invii ]
  #before_filter :newsletter_members, :only => [ :invii ]

  verify :method => :post, :only => [ :destroy ],
         :redirect_to => { :action => :index }

  include FeesHelper  #Domthu  FeeConst
  helper :sort
  include SortHelper

  #gestione invii emails di una newsletter e imposti tutti utenti ad essa collegata
  # pass project_id
  #: {"role"=>{"role_id"=>"1"}, "convention"=>{"convention_id"=>""}, "project_id"=>"341", "controller"=>"newsletters", "name"=>"domthu", "action"=>"invii"}
  def invii
    puts "@project id " + @project.id.to_s +  ", @newsletter id " + @newsletter.id.to_s

    #if params[:member] && request.post?
    if request.post?

    else
      if @newsletter.newsletter_users.count > 0
        @last_date = @newsletter.newsletter_users.sort_by(&:updated_at).reverse.first.updated_at
        if @last_date && @newsletter.data < @last_date
          @newsletter.data = @last_date
          @newsletter.save
        end
      else
        @newsletter.data = DateTime.now
        @newsletter.save
      end
    end

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @newsletter_user }
    end
  end


    #Collect user
#    @users_by_roles = User.all(
#      :conditions => ['role_id IN (?)', FeeConst::NEWSLETTER_ROLES]
#      )

    # if convention_id is not null allora sono NON pagante
    #@users_emailed = @newsletter.newsletter_users

#    #sort and filters users
#    sort_init 'login', 'asc'
#    #sort_update %w(login firstname lastname mail admin created_on last_login_on)
#    sort_update %w(lastname mail data convention_id role_id)

#    #@limit = per_page_option

#    scope = @users_by_roles

#    c = ARCondition.new(["users.type = 'User'"])
#    if request.post?
#      @role = params[:role] ? params[:role].to_i : 0
#      if (@role > 0)
#        c << ["role_id = ?", @role]
#      #else
#      #  c << ["role_id IN (?) ", FeeConst::NEWSLETTER_ROLES]
#      end
#      #ricerca testuale
#      unless params[:name].blank?
#        @name = params[:name]
#        name = "%#{params[:name].strip.downcase}%"
#        c << ["LOWER(login) LIKE ? OR LOWER(firstname) LIKE ? OR LOWER(lastname) LIKE ? OR LOWER(mail) LIKE ?", name, name, name, name]
#      end
#      #Convention filter
#      @convention_id = (params[:convention] && params[:convention][:convention_id]) ? params[:convention][:convention_id].to_i : 0
#      if @convention_id > 0
#        c << ["convention_id = ? ", @convention_id.to_s]
#      end
#    else
#      @role = params[:role] ? params[:role].to_i : 0

#    end

#    #@user_count = scope.count(:conditions => c.conditions)
#    #@user_count = User.all.count(:conditions => c.conditions)
#    #@user_pages = Paginator.new self, @user_count, @limit, params['page']
#    #@offset ||= @user_pages.current.offset
#    #@users =  scope.find :all,
#    #@users =  User.find :all,
#    #            :order => sort_clause,
#    #            :conditions => c.conditions,
#    #            :limit  =>  @limit,
#    #            :offset =>  @offset

#    @users =  User.find :all,
#                :order => sort_clause,
#                :conditions => c.conditions


  # GET /newsletters
  # GET /newsletters.xml
  def index
    @newsletters = Newsletter.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @newsletters }
    end
  end

  # GET /newsletters/1
  # GET /newsletters/1.xml
  def show
    @newsletter = Newsletter.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @newsletter }
    end
  end

  # GET /newsletters/new
  # GET /newsletters/new.xml
  def new
    @newsletter = Newsletter.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @newsletter }
    end
  end

  # GET /newsletters/1/edit
  def edit
    @newsletter = Newsletter.find(params[:id])
  end

  # POST /newsletters
  # POST /newsletters.xml
  def create
    @newsletter = Newsletter.new(params[:newsletter])

    respond_to do |format|
      if @newsletter.save
        format.html { redirect_to(@newsletter, :notice => 'Newsletter was successfully created.') }
        format.xml  { render :xml => @newsletter, :status => :created, :location => @newsletter }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @newsletter.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /newsletters/1
  # PUT /newsletters/1.xml
  def update
    @newsletter = Newsletter.find(params[:id])

    respond_to do |format|
      if @newsletter.update_attributes(params[:newsletter])
        format.html { redirect_to(@newsletter, :notice => 'Newsletter was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @newsletter.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /newsletters/1
  # DELETE /newsletters/1.xml
  def destroy
    @newsletter = Newsletter.find(params[:id])
    @newsletter.destroy

    respond_to do |format|
      format.html { redirect_to(newsletters_url) }
      format.xml  { head :ok }
    end
  end

################################
  private

#    def newsletter_members

#      #ruoli
#      @num_no_role_count = User.all(:conditions => {:role_id => nil || 2}).count
#      @name_admin_count = User.all(:conditions => {:admin => 1}).count
#      @name_manager_count = User.all(:conditions => {:role_id => FeeConst::ROLE_MANAGER}).count
#      @name_author_count = User.all(:conditions => {:role_id => FeeConst::ROLE_AUTHOR}).count
#      #@name_collaboratori_count = User.all(:conditions => {:role_id => ROLE_COLLABORATOR}).count
#      @name_invitati_count = User.all(:conditions => {:role_id => FeeConst::ROLE_VIP}).count
#      @num_uncontrolled_TOTAL = @name_manager_count + @name_author_count + @name_invitati_count


#      #BY CLIENT ROLE
#      #  FeeConst::ROLE_ABBONATO       = 5  #user.data_scadenza > (today - Setting.renew_days)
#      #  FeeConst::ROLE_RENEW          = 8  #periodo prima della scadenza dipende da Setting.renew_days
#      #  FeeConst::ROLE_REGISTERED     = 7  #periodo di prova durante Setting.register_days
#      #  FeeConst::ROLE_EXPIRED        = 6  #user.data_scadenza < today
#      #  FeeConst::ROLE_ARCHIVIED      = 4  #bloccato: puo uscire da questo stato solo manualmente ("Ha pagato", "invito di prova"=REGISTERED)
#      @num_abbonati = User.all(:conditions => {:convention_id => nil, :role_id => FeeConst::ROLE_ABBONATO}).count
#      @num_rinnovamento = User.all(:conditions => {:convention_id => nil, :role_id => FeeConst::ROLE_RENEW}).count
#      @num_registrati = User.all(:conditions => {:convention_id => nil, :role_id => FeeConst::ROLE_REGISTERED}).count
#      @num_scaduti = User.all(:conditions => {:convention_id => nil, :role_id => FeeConst::ROLE_EXPIRED}).count
#      @num_archiviati = User.all(:conditions => {:convention_id => nil, :role_id => FeeConst::ROLE_ARCHIVIED}).count
#      @num_controlled_TOTAL = @num_abbonati + @num_rinnovamento + @num_registrati + @num_scaduti + @num_archiviati

#      #Who pay? User member of organismo convenzionato
#      @num_Associations =  Convention.all.count
#      #questi utenti non pagano. Paga l'organismo convenzionato
#      @num_Associated_COUNT =  User.all(:conditions => 'convention_id IS NOT NULL').count

#      #@roles = []
#      #@roles << FeeConst::ROLE_MANAGER << FeeConst::ROLE_AUTHOR << FeeConst::ROLE_VIP
#      #@num_privati_COUNT = User.all(:conditions => ['convention_id is null AND role_id not IN (?)', @roles]).count

#    end

    def require_fee
      if !Setting.fee
        flash[:notice] = l(:notice_setting_fee_not_allowed)
        redirect_to editorial_path
      end
    end

    def find_project
      if params[:project_id].empty?
        flash[:notice] = l(:error_can_not_create_newsletter, :newsletter => "manca id del progetto")
        return redirect_to :controller => 'projects', :action => 'index'
      end
      #@project = Project.find(params[:project_id])
      @project = Project.all_public_fs.find_by_id params[:project_id].to_i
      if @project.nil?
        flash[:error] = l(:error_can_not_create_newsletter, :newsletter => "edizione non trovata")
        return redirect_to :controller => 'projects', :action => 'index'
      end
    rescue ActiveRecord::RecordNotFound
      render_404
    end

    def find_newsletter
      @newsletter = Newsletter.find_by_project(@project.id)
      if @newsletter.nil?
        #automatic create Newsletter
        @newsletter = Newsletter.new
        #@newsletter.project_id = params[:project_id].to_i
        @newsletter.project_id = @project.id
        @newsletter.data = DateTime.now
        #TODO fare una newsletter vuota
        #@newsletter.html = @project.newsletter_smtp(nil)
        #@newsletter.html = @project.newsletter_smtp(User.current)
        #@newsletter.html = "project.rb:934:in newsletter_smtp undefined method > for nil:NilClass"
        #undefined method `image_tag' for #<Project:0xb5934b0c>
        @art = @project.issues.all(:order => "#{Section.table_name}.top_section_id DESC", :include => [:section => :top_section])
        @newsletter.html = render_to_string(
                :layout => false,
                :partial => 'editorial/edizione_smtp',
                :locals => { :id => @id, :project => @project, :art => @art, :user => nil }
              )
        #@@user_name
        #@@user_convention
        #@@user_convention_icon
        @newsletter.sended = false
        if !@newsletter.save
          flash[:error] = l(:error_can_not_create_newsletter, :newsletter => @project.name)
          return redirect_to :controller => 'projects', :action => 'show', :id => @project
        end
      end
    end

end

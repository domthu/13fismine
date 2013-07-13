class NewslettersController < ApplicationController
  layout 'admin'

  before_filter :require_admin
  before_filter :find_project, :only => [ :invii ]
  before_filter :find_newsletter, :only => [ :invii ]

  verify :method => :post, :only => [ :destroy ],
         :redirect_to => { :action => :index }

  include FeesHelper  #Domthu  FeeConst
  helper :sort
  include SortHelper

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

  #gestione invii emails di una newsletter e imposti tutti utenti ad essa collegata
  # pass project_id
  #: {"role"=>"1", "convention"=>{"convention_id"=>""}, "project_id"=>"341", "controller"=>"newsletters", "name"=>"domthu", "action"=>"invii"}

  def invii
    puts "@project id " + @project.id.to_s +  ", @newsletter id " + @newsletter.id.to_s
    #Collect user
    @users_by_roles = User.all(
      :conditions => ['role_id IN (?)', FeeConst::NEWSLETTER_ROLES]
      )
    # if convention_id is not null allora sono NON pagante
    @users_emailed = @newsletter.newsletter_users

    #sort and filters users
    sort_init 'login', 'asc'
    #sort_update %w(login firstname lastname mail admin created_on last_login_on)
    sort_update %w(lastname mail data convention_id role_id)

    #@limit = per_page_option

    scope = @users_by_roles

    c = ARCondition.new(["users.type = 'User'"])
    if request.post?
      @role = params[:role] ? params[:role].to_i : 0
      if (@role > 0)
        c << ["role_id = ?", @role]
      #else
      #  c << ["role_id IN (?) ", FeeConst::NEWSLETTER_ROLES]
      end
      #ricerca testuale
      unless params[:name].blank?
        @name = params[:name]
        name = "%#{params[:name].strip.downcase}%"
        c << ["LOWER(login) LIKE ? OR LOWER(firstname) LIKE ? OR LOWER(lastname) LIKE ? OR LOWER(mail) LIKE ?", name, name, name, name]
      end
      #Convention filter
      @convention_id = (params[:convention] && params[:convention][:convention_id]) ? params[:convention][:convention_id].to_i : 0
      if @convention_id > 0
        c << ["convention_id = ? ", @convention_id.to_s]
      end
    else
      @role = params[:role] ? params[:role].to_i : 0

    end

    #@user_count = scope.count(:conditions => c.conditions)
    #@user_count = User.all.count(:conditions => c.conditions)
    #@user_pages = Paginator.new self, @user_count, @limit, params['page']
    #@offset ||= @user_pages.current.offset
    #@users =  scope.find :all,
    #@users =  User.find :all,
    #            :order => sort_clause,
    #            :conditions => c.conditions,
    #            :limit  =>  @limit,
    #            :offset =>  @offset

    @users =  User.find :all,
                :order => sort_clause,
                :conditions => c.conditions

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @newsletter_user }
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

  private

################################
  private

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
      @project = Project.find(params[:project_id])
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
        #@newsletter.text = @project.newsletter_smtp(User.current)
        @newsletter.html = "project.rb:934:in newsletter_smtp undefined method > for nil:NilClass"
        @newsletter.sended = false
        if !@newsletter.save
          flash[:error] = l(:error_can_not_create_newsletter, :newsletter => @project.name)
          return redirect_to :controller => 'projects', :action => 'show', :id => @project
        end
      end
    end

end

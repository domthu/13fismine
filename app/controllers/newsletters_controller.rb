class NewslettersController < ApplicationController
  layout 'admin'

  before_filter :require_admin

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
  def invii
    if params[:project_id].empty?
      flash[:notice] = l(:error_can_not_create_newsletter, :newsletter => "manca id del progetto")
      return redirect_to :action => 'index'
    end
    @project = Project.find(params[:project_id])
    if @project.nil?
      flash[:error] = l(:error_can_not_create_newsletter, :newsletter => "edizione non trovata")
      return redirect_to :action => 'index'
    end
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
        return redirect_to :action => 'index'
      end
    end

    #Collect user
    @users_by_roles = User.all(:conditions => ['role_id IN (?)', FeeConst::NEWSLETTER_ROLES])
    # if asso_id is not null allora sono non pagante
    @users_emailed = @newsletter.newsletter_users

    #sort and filters users
    sort_init 'login', 'asc'
    sort_update %w(login firstname lastname mail admin created_on last_login_on)
    @limit = per_page_option

    scope = @users_by_roles

    @role = params[:role] ? params[:role].to_i : 1
    c = ARCondition.new(@role == 0 ? ["role_id IN ? ", FeeConst::NEWSLETTER_ROLES] : ["role_id = ?", @role])

    unless params[:name].blank?
      name = "%#{params[:name].strip.downcase}%"
      c << ["LOWER(login) LIKE ? OR LOWER(firstname) LIKE ? OR LOWER(lastname) LIKE ? OR LOWER(mail) LIKE ?", name, name, name, name]
    end

    @user_count = scope.count(:conditions => c.conditions)
    @user_pages = Paginator.new self, @user_count, @limit, params['page']
    @offset ||= @user_pages.current.offset
    @users =  scope.find :order => sort_clause,
                        :conditions => c.conditions,
                        :limit  =>  @limit,
                        :offset =>  @offset
#    @cross_groups = CrossGroup.find(:all,
#                              :order => sort_clause,
#                              :limit  =>  @cross_group_pages.items_per_page,
#                              :include => [:asso, :group_banner],
#                              :offset =>  @cross_group_pages.current.offset)

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
end

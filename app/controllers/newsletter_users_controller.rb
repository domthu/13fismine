class NewsletterUsersController < ApplicationController
  layout 'admin'

  before_filter :require_admin

  verify :method => [:post, :delete], :only => [ :destroy ],
         :redirect_to => { :action => :index }

  include FeesHelper  #Domthu  FeeConst get_role_css

  # GET /newsletter_users
  # GET /newsletter_users.xml
  def index
    @newsletter_users = NewsletterUser.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @newsletter_users }
    end
  end

  # GET /newsletter_users/1
  # GET /newsletter_users/1.xml
  def show
    @newsletter_user = NewsletterUser.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @newsletter_user }
    end
  end

  # GET /newsletter_users/new
  # GET /newsletter_users/new.xml
  def new
    @newsletter_user = NewsletterUser.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @newsletter_user }
    end
  end

  # GET /newsletter_users/1/edit
  def edit
    @newsletter_user = NewsletterUser.find(params[:id])
  end

  # POST /newsletter_users
  # POST /newsletter_users.xml
  def create
    @newsletter_user = NewsletterUser.new(params[:newsletter_user])

    respond_to do |format|
      if @newsletter_user.save
        format.html { redirect_to(@newsletter_user, :notice => 'NewsletterUser was successfully created.') }
        format.xml  { render :xml => @newsletter_user, :status => :created, :location => @newsletter_user }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @newsletter_user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /newsletter_users/1
  # PUT /newsletter_users/1.xml
  def update
    @newsletter_user = NewsletterUser.find(params[:id])

    respond_to do |format|
      if @newsletter_user.update_attributes(params[:newsletter_user])
        format.html { redirect_to(@newsletter_user, :notice => 'NewsletterUser was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @newsletter_user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /newsletter_users/1
  # DELETE /newsletter_users/1.xml
  def destroy
    @newsletter_user = NewsletterUser.find(params[:id])
    @newsletter_user.destroy

    if request.xhr?
      render :json => { :success => true }
    else
      respond_to do |format|
        format.html { redirect_to(newsletter_users_url) }
        format.xml  { head :ok }
      end
    end
  end
end

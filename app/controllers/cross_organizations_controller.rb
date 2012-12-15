class CrossOrganizationsController < ApplicationController
  layout 'admin'

  before_filter :require_admin

  helper :sort
  include SortHelper

  # GET /cross_organizations
  # GET /cross_organizations.xml
  def index
    #@cross_organizations = CrossOrganization.all
    #respond_to do |format|
    #  format.html # index.html.erb
    #  format.xml  { render :xml => @cross_organizations }
    #end

    #Sorting
    sort_init 'organizzazione'
    sort_update 'organizzazione' => 'organizzazione',
                'type_organization' => 'type_organization',
                'sigla' => 'sigla',
                'se_visibile' => 'se_visibile'
  
    respond_to do |format|
      #ovverride for paging format.html # index.html.erb
      format.html {
        # Paginate results
        @cross_organization_count = CrossOrganization.all.count
        @cross_organization_pages = Paginator.new self, @cross_organization_count, per_page_option, params['page']
        @cross_organizations = CrossOrganization.find(:all,
                          :order => sort_clause,
                          :limit  =>  @cross_organization_pages.items_per_page,
                          :offset =>  @cross_organization_pages.current.offset)
        render :layout => !request.xhr?
      }
      format.xml  { render :xml => @cross_organizations }
    end
  end

  # GET /cross_organizations/1
  # GET /cross_organizations/1.xml
  def show
    @cross_organization = CrossOrganization.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @cross_organization }
    end
  end

  # GET /cross_organizations/new
  # GET /cross_organizations/new.xml
  def new
    @cross_organization = CrossOrganization.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @cross_organization }
    end
  end

  # GET /cross_organizations/1/edit
  def edit
    @cross_organization = CrossOrganization.find(params[:id])
  end

  # POST /cross_organizations
  # POST /cross_organizations.xml
  def create
    @cross_organization = CrossOrganization.new(params[:cross_organization])

    respond_to do |format|
      if @cross_organization.save
        format.html { redirect_to(@cross_organization, :notice => l(:notice_successful_create)) }
        format.xml  { render :xml => @cross_organization, :status => :created, :location => @cross_organization }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @cross_organization.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /cross_organizations/1
  # PUT /cross_organizations/1.xml
  def update
    @cross_organization = CrossOrganization.find(params[:id])

    respond_to do |format|
      if @cross_organization.update_attributes(params[:cross_organization])
        format.html { redirect_to(@cross_organization, :notice => l(:notice_successful_update)) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @cross_organization.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /cross_organizations/1
  # DELETE /cross_organizations/1.xml
  def destroy
    @cross_organization = CrossOrganization.find(params[:id])
    @cross_organization.destroy

    respond_to do |format|
      format.html { redirect_to(cross_organizations_url) }
      format.xml  { head :ok }
    end
  end
end

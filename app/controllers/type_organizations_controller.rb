class TypeOrganizationsController < ApplicationController
  layout 'admin'

  before_filter :require_admin

  helper :sort
  include SortHelper

  # GET /type_organizations
  # GET /type_organizations.xml
  def index
    #@type_organizations = TypeOrganization.all
    #respond_to do |format|
    #  format.html # index.html.erb
    #  format.xml  { render :xml => @type_organizations }
    #end

    #Sorting
    sort_init 'priorita'
    sort_update 'tipo' => 'tipo',
                'priorita' => 'priorita'

    respond_to do |format|
      #ovverride for paging format.html # index.html.erb
      format.html {
        # Paginate results
        @type_organization_count = TypeOrganization.all.count
        @type_organization_pages = Paginator.new self, @type_organization_count, per_page_option, params['page']
        @type_organizations = TypeOrganization.find(:all,
                          :order => sort_clause,
                          :limit  =>  @type_organization_pages.items_per_page,
                          :offset =>  @type_organization_pages.current.offset)
        render :layout => !request.xhr?
      }
      format.xml  { render :xml => @type_organizations }
    end
  end

  # GET /type_organizations/1
  # GET /type_organizations/1.xml
  def show
    @type_organization = TypeOrganization.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @type_organization }
    end
  end

  # GET /type_organizations/new
  # GET /type_organizations/new.xml
  def new
    @type_organization = TypeOrganization.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @type_organization }
    end
  end

  # GET /type_organizations/1/edit
  def edit
    @type_organization = TypeOrganization.find(params[:id])
  end

  # POST /type_organizations
  # POST /type_organizations.xml
  def create
    @type_organization = TypeOrganization.new(params[:type_organization])

    respond_to do |format|
      if @type_organization.save
        format.html { redirect_to(@type_organization, :notice => l(:notice_successful_create)) }
        format.xml  { render :xml => @type_organization, :status => :created, :location => @type_organization }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @type_organization.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /type_organizations/1
  # PUT /type_organizations/1.xml
  def update

    @type_organization = TypeOrganization.find(params[:id])

    respond_to do |format|
      if @type_organization.update_attributes(params[:type_organization])
        format.html { redirect_to(@type_organization, :notice => l(:notice_successful_update)) }
        format.xml  { head :ok }
        format.json  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @type_organization.errors, :status => :unprocessable_entity }
        format.json {  head :ko }
      end

    end
  end

  # DELETE /type_organizations/1
  # DELETE /type_organizations/1.xml
  def destroy
    @type_organization = TypeOrganization.find(params[:id])
    @type_organization.destroy

    respond_to do |format|
      format.html { redirect_to(type_organizations_url) }
      format.xml  { head :ok }
    end
  end
end

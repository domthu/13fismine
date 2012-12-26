class OrganizationsController < ApplicationController
  layout 'admin'

  before_filter :require_admin

  helper :sort
  include SortHelper

  # GET /organizations
  # GET /organizations.xml
  def index
    #@organizations = Organization.all
    #respond_to do |format|
    #  format.html # index.html.erb
    #  format.xml  { render :xml => @organizations }
    #end

    #Sorting
    sort_init 'Org. Asso'
    sort_update 'Org. Asso' => "assos.ragione_sociale",   #TODO related table.Field
                #'Tipo_Sigla' => 'cross_organizations.sigla',   #related table.Field
                'Tipo_Sigla' => 'type_organizations.tipo, cross_organizations.sigla',   #related table.Field
                'responsabile' => 'users.firstname, users.lastname',   #related table.Field
                'province' => 'provinces.name',   #related table.Field
                'comune' => 'comunes.name',   #related table.Field
                'scadenza' => 'data_scadenza',
                'ConiNum?' => 'richiedinumeroregistrazione'
#'asso_name' => "assos.ragione_sociale",   #related table.Field
#Mysql::Error: Unknown column 'assos.ragione_sociale' in 'order clause': SELECT * FROM `organizations`  ORDER BY assos.ragione_sociale LIMIT 0, 2

    respond_to do |format|
      #ovverride for paging format.html # index.html.erb
      format.html {
        # Paginate results
        @organization_count = Organization.all.count
        @organization_pages = Paginator.new self, @organization_count, per_page_option, params['page']
        @organizations = Organization.find(:all,
                          :order => sort_clause,
                          :include => [:asso, :province, :comune, :user, {:cross_organization => [:type_organization]}],
                          :limit  =>  @organization_pages.items_per_page,
                          :offset =>  @organization_pages.current.offset)
        render :layout => !request.xhr?
      }
      format.xml  { render :xml => @organizations }
    end
  end

  # GET /organizations/1
  # GET /organizations/1.xml
  def show
    @organization = Organization.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @organization }
    end
  end

  # GET /organizations/new
  # GET /organizations/new.xml
  def new
    @organization = Organization.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @organization }
    end
  end

  # GET /organizations/1/edit
  def edit
    @organization = Organization.find(params[:id])
  end

  # POST /organizations
  # POST /organizations.xml
  def create
    @organization = Organization.new(params[:organization])

    respond_to do |format|
      if @organization.save
        format.html { redirect_to(@organization, :notice => l(:notice_successful_create)) }
        format.xml  { render :xml => @organization, :status => :created, :location => @organization }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @organization.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /organizations/1
  # PUT /organizations/1.xml
  def update
    @organization = Organization.find(params[:id])

    respond_to do |format|
      if @organization.update_attributes(params[:organization])
        format.html { redirect_to(@organization, :notice => l(:notice_successful_update)) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @organization.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /organizations/1
  # DELETE /organizations/1.xml
  def destroy
    @organization = Organization.find(params[:id])
    @organization.destroy

    respond_to do |format|
      format.html { redirect_to(organizations_url) }
      format.xml  { head :ok }
    end
  end
end

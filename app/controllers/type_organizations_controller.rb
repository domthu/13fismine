class TypeOrganizationsController < ApplicationController
  layout 'admin'

  before_filter :require_admin
  before_filter :set_menu
  helper :sort
  include SortHelper
  menu_item :type_organizations
  def set_menu
    @menu_fs = :menu_fiscosport
  end
  def index
    #Sorting
    sort_init  'se_sportivo'
    sort_update 'tipo' => 'tipo',
                'se_sportivo' => 'type_sport'

    respond_to do |format|
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

  def show
    @type_organization = TypeOrganization.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @type_organization }
    end
  end

  def new
    @type_organization = TypeOrganization.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @type_organization }
    end
  end

  def edit
    @type_organization = TypeOrganization.find(params[:id])
  end


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

  def update
    @type_organization = TypeOrganization.find(params[:id])

    respond_to do |format|
      if @type_organization.update_attributes(params[:type_organization])
        format.html { redirect_to(@type_organization, :notice => l(:notice_successful_update)) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @type_organization.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @type_organization = TypeOrganization.find(params[:id])
    @type_organization.destroy

    respond_to do |format|
      format.html { redirect_to(type_organizations_url) }
      format.xml  { head :ok }
    end
  end
end

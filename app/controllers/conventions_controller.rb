class ConventionsController < ApplicationController
  layout 'admin'

  before_filter :require_admin

  helper :sort
  include SortHelper
  #
  menu_item :conventions
  before_filter :set_menu
  def set_menu
    @menu_fs = :menu_fiscosport
  end
  # GET /conventions
  # GET /conventions.xml
  def index
    #@convs = Convention.all

    #Sorting
    sort_init 'data_scadenza DESC'
    sort_update 'ragione_sociale' => 'ragione_sociale',
                'email' => 'email',
                'indirizzo' => "indirizzo",
                'presidente' => 'presidente',
                'referente' => 'referente',
                'consulente' => 'consulente',
                'logo' => 'logo',
                'telefono' => 'telefono',
                'fax' => 'fax',
                'Tipo_Sigla' => 'type_organizations.tipo, cross_organizations.sigla',   #related table.Field
                'regione' => 'regions.name',   #related table.Field
                'province' => 'provinces.name',   #related table.Field
                'comune' => 'comunes.name',   #related table.Field
                'responsabile' => 'users.firstname, users.lastname',   #related table.Field
                'scadenza' => 'data_scadenza',
                'ConiNum?' => 'richiedinumeroregistrazione'

    respond_to do |format|
      #ovverride for paging format.html # index.html.erb
      format.html {
#        # Paginate results
#        @conv_count = Convention.all.count
#        @conv_pages = Paginator.new self, @conv_count, per_page_option, params['page']
#        @convs = Convention.find(:all,
#                          :order => sort_clause,
#                          :limit  =>  @conv_pages.items_per_page,
#                          :include => [:province, :comune, :user, {:cross_organization => [:type_organization]}],
#                          :offset =>  @conv_pages.current.offset)
        # Unpaginate results
        @convs = Convention.find(:all,
                          :order => sort_clause,
                          :include => [:province, :comune, :user, {:cross_organization => [:type_organization]}]
                          )
        render :layout => !request.xhr?
      }
      format.xml  { render :xml => @convs }
    end
  end

  # GET /conventions/1
  # GET /conventions/1.xml
  def show
    @conv = Convention.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @conv }
    end
  end

  # GET /conventions/new
  # GET /conventions/new.xml
  def new
    @conv = Convention.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @conv }
    end
  end

  # GET /conventions/1/edit
  def edit
    #@conv = Convention.find(params[:id], :include => [:user])
    @conv = Convention.find(params[:id])
  end

  # POST /conventions
  # POST /conventions.xml
  def create
    @conv = Convention.new(params[:convention])

    respond_to do |format|
      if @conv.save
        format.html { redirect_to(@conv, :notice => l(:notice_successful_create)) }
        format.xml  { render :xml => @conv, :status => :created, :location => @conv }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @conv.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /conventions/1
  # PUT /conventions/1.xml
  def update
    @conv = Convention.find(params[:id])

    respond_to do |format|
      if @conv.update_attributes(params[:convention])
        format.html { redirect_to(@conv, :notice => l(:notice_successful_update)) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @conv.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /conventions/1
  # DELETE /conventions/1.xml
  def destroy
    @conv = Convention.find(params[:id])
    @conv.destroy

    @user = User.all(:conditions => {:convention_id => params[:id]})
    @user.each do |usr|
      usr.convention_id = nil
      usr.save!  #--> save_without_transactions
    end

    respond_to do |format|
      format.html { redirect_to(conventions_url) }
      format.xml  { head :ok }
    end
  end
end

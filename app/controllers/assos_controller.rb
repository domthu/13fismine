class AssosController < ApplicationController
  layout 'admin'

  before_filter :require_admin

  helper :sort
  include SortHelper

  # GET /assos
  # GET /assos.xml
  def index
    #@assos = Asso.all

    #Sorting
    sort_init 'ragione_sociale'
    sort_update 'ragione_sociale' => 'ragione_sociale',
                'email' => 'email',
                'indirizzo' => "indirizzo",  
                'presidente' => 'presidente',
                'referente' => 'referente',
                'consulente' => 'consulente',
                'logo' => 'logo',
                'telefono' => 'telefono',
                'fax' => 'fax'

    respond_to do |format|
      #ovverride for paging format.html # index.html.erb
      format.html {
        # Paginate results
        @asso_count = Asso.all.count
        @asso_pages = Paginator.new self, @asso_count, per_page_option, params['page']
        @assos = Asso.find(:all,
                          :order => sort_clause,
                          :limit  =>  @asso_pages.items_per_page,
                          :offset =>  @asso_pages.current.offset)
        render :layout => !request.xhr?
      }
      format.xml  { render :xml => @assos }
    end
  end

  # GET /assos/1
  # GET /assos/1.xml
  def show
    @asso = Asso.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @asso }
    end
  end

  # GET /assos/new
  # GET /assos/new.xml
  def new
    @asso = Asso.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @asso }
    end
  end

  # GET /assos/1/edit
  def edit
    @asso = Asso.find(params[:id])
  end

  # POST /assos
  # POST /assos.xml
  def create
    @asso = Asso.new(params[:asso])

    respond_to do |format|
      if @asso.save
        format.html { redirect_to(@asso, :notice => l(:notice_successful_create)) }
        format.xml  { render :xml => @asso, :status => :created, :location => @asso }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @asso.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /assos/1
  # PUT /assos/1.xml
  def update
    @asso = Asso.find(params[:id])

    respond_to do |format|
      if @asso.update_attributes(params[:asso])
        format.html { redirect_to(@asso, :notice => l(:notice_successful_update)) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @asso.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /assos/1
  # DELETE /assos/1.xml
  def destroy
    @asso = Asso.find(params[:id])
    @asso.destroy

    respond_to do |format|
      format.html { redirect_to(assos_url) }
      format.xml  { head :ok }
    end
  end
end

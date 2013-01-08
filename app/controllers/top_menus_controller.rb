class TopMenusController < ApplicationController
  layout 'admin'

  before_filter :require_admin

  helper :sort
  include SortHelper

  # GET /top_menus
  # GET /top_menus.xml
  def index
    #@top_menus = TopMenu.all

    #Sorting
    sort_init 'descrizione'
    sort_update 'descrizione' => "'description'",
                'ordinamento' => "'order'"

    respond_to do |format|
      #ovverride for paging format.html # index.html.erb
      format.html {
        # Paginate results
        @top_menu_count = TopMenu.all.count
        @top_menu_pages = Paginator.new self, @top_menu_count, per_page_option, params['page']
        @top_menus = TopMenu.find(:all,
                                  :order => sort_clause,
                                  :limit  =>  @top_menu_pages.items_per_page,
                                  :offset =>  @top_menu_pages.current.offset)
        render :layout => !request.xhr?
      }
      format.xml  { render :xml => @sections }
    end
  end

  # GET /top_menus/1
  # GET /top_menus/1.xml
  def show
    @top_menu = TopMenu.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @top_menu }
    end
  end

  # GET /top_menus/new
  # GET /top_menus/new.xml
  def new
    @top_menu = TopMenu.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @top_menu }
    end
  end

  # GET /top_menus/1/edit
  def edit
    @top_menu = TopMenu.find(params[:id])
  end

  # POST /top_menus
  # POST /top_menus.xml
  def create
    @top_menu = TopMenu.new(params[:top_menu])

    respond_to do |format|
      if @top_menu.save
        format.html { redirect_to(@top_menu, :notice => 'TopMenu was successfully created.') }
        format.xml  { render :xml => @top_menu, :status => :created, :location => @top_menu }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @top_menu.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /top_menus/1
  # PUT /top_menus/1.xml
  def update
    @top_menu = TopMenu.find(params[:id])

    respond_to do |format|
      if @top_menu.update_attributes(params[:top_menu])
        format.html { redirect_to(@top_menu, :notice => 'TopMenu was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @top_menu.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /top_menus/1
  # DELETE /top_menus/1.xml
  def destroy
    @top_menu = TopMenu.find(params[:id])
    if @top_menu.top_sections.count > 0
      flash[:error] = l(:error_can_not_delete_top_menu_unless_sections)
      return redirect_to :action => 'index'
    else
      @top_menu.destroy
    end
    respond_to do |format|
      format.html { redirect_to(top_menus_url) }
      format.xml  { head :ok }
    end
  end
end

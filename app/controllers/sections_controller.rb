class SectionsController < ApplicationController
  layout 'admin'

  before_filter :require_admin

  helper :sort
  include SortHelper
  include FeesHelper
  before_filter :set_menu
  menu_item :sections
  def set_menu
    @menu_fs = :menu_fiscosport
  end
  # GET /sections
  # GET /sections.xml
  def index
    #@sections = Section.all

    #Sorting
    sort_init 'categoria'
    sort_update 'categoria' => 'sezione',
                #'sezione' => 'sezione_top_id',
                'sezione' => "top_sections.sezione_top",   #related table.Field
                'ord.' => 'sections.ordinamento',
                'protetto' => 'protetto'


    respond_to do |format|
      #ovverride for paging format.html # index.html.erb
      format.html {
        # Paginate results
        @section_count = Section.all.count
        @section_pages = Paginator.new self, @section_count, per_page_option, params['page']
        @sections = Section.find(:all,
                                  :order => sort_clause,
                                  :limit  =>  @section_pages.items_per_page,
                                  :include => [:top_section],
                                  :offset =>  @section_pages.current.offset)
        render :layout => !request.xhr?
      }
      format.xml  { render :xml => @sections }
    end
  end

  # GET /sections/1
  # GET /sections/1.xml
  def show
    @section = Section.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @section }
    end
  end

  # GET /sections/new
  # GET /sections/new.xml
  def new
    @section = Section.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @section }
    end
  end

  # GET /sections/1/edit
  def edit
    @section = Section.find(params[:id])
  end

  # POST /sections
  # POST /sections.xml
  def create
    @section = Section.new(params[:section])

    respond_to do |format|
      if @section.save
        format.html { redirect_to(@section, :notice => l(:notice_successful_create)) }
        format.xml  { render :xml => @section, :status => :created, :location => @section }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @section.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /sections/1
  # PUT /sections/1.xml
  def update
    @section = Section.find(params[:id])

    respond_to do |format|
      if @section.update_attributes(params[:section])
        format.html { redirect_to(@section, :notice => l(:notice_successful_update)) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @section.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /sections/1
  # DELETE /sections/1.xml
  def destroy
    @section = Section.find(params[:id])
    if !@section.nil? && !@section.issues.empty? && @section.issues.count > 0
      flash[:error] = l(:error_can_not_delete_section_unless_issues)
      flash[:notice] = "Verificare la lista degli articoli (" + @section.issues.count.to_s + ") legati qui sotto <ol>"
      @section.issues.each do |art|
        flash[:notice] += "<li>" + art.to_s + "</li>"
      end
      flash[:notice] += "</ol>"
    else
      if @section.id == FeeConst::DEFAULT_SECTION
        flash[:error] = l(:error_can_not_delete_system, :name => "questa sotto sezione")
      else
        @section.destroy
      end
    end

    respond_to do |format|
      format.html { redirect_to(sections_url) }
      format.xml  { head :ok }
    end
  end
end

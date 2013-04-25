class TopSectionsController < ApplicationController
  layout 'admin'
  before_filter :require_admin
  helper :sort
  include SortHelper
  include FeesHelper

  def index
    sort_init 'sezione_top'
    sort_update 'sezione_top' => 'sezione_top',
                'ordinamento' => 'ordinamento',
                'chiave' => 'top_sections.key',
                'menu' => "top_menus.description",
                'se_visible' => 'se_visible'
    respond_to do |format|
      format.html {
        @top_section_count = TopSection.all.count
        @top_section_pages = Paginator.new self, @top_section_count, per_page_option, params['page']
        @top_sections = TopSection.find(:all,
                                        :include => [:top_menu],
                                        :order => sort_clause,
                                        :limit => @top_section_pages.items_per_page,
                                        :offset => @top_section_pages.current.offset)

        render :layout => !request.xhr?
      }
      format.xml { render :xml => @top_sections }
    end
  end

  # GET /top_sections/1
  # GET /top_sections/1.xml
  def show
    @top_section = TopSection.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml { render :xml => @top_section }
    end
  end

  # GET /top_sections/new
  # GET /top_sections/new.xml
  def new
    @top_section = TopSection.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml { render :xml => @top_section }
    end
  end

  # GET /top_sections/1/edit
  def edit
    @top_section = TopSection.find(params[:id])

  end

  # POST /top_sections
  # POST /top_sections.xml
  def create
    @top_section = TopSection.new(params[:top_section])

    respond_to do |format|
      if @top_section.save
        format.html {
          flash[:notice] = l(:notice_top_section_successful_create, :id => "<a href='#{top_section_path(@top_section)}'>##{@top_section.id}</a>")
          redirect_to(@top_section) }
        format.xml { render :xml => @top_section, :status => :created, :location => @top_section }
      else
        format.html { render :action => "new" }
        format.xml { render :xml => @top_section.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /top_sections/1
  # PUT /top_sections/1.xml
  def update
    @top_section = TopSection.find(params[:id])

    respond_to do |format|
      if @top_section.update_attributes(params[:top_section])
        format.html { redirect_to(@top_section, :notice => l(:notice_successful_update)) }
        format.xml { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml { render :xml => @top_section.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /top_sections/1
  # DELETE /top_sections/1.xml
  def destroy
    @top_section = TopSection.find(params[:id])
    if !@top_section.nil? && !@top_section.sections.empty? && @top_section.sections.count > 0
      flash[:error] = l(:error_can_not_delete_topsection_unless_sections)
      flash[:notice] = "Verificare la lista delle sotto sezioni (" + @top_section.sections.count.to_s + ") qui sotto <ol>"
      @top_section.sections.each do |sec|
        flash[:notice] += "<li>" + sec.full_name + "</li>"
      end
      flash[:notice] += "</ol>"
    else
      if @top_section.id == FeeConst::DEFAULT_TOP_SECTION
        flash[:error] = l(:error_can_not_delete_system, :name => "questa sezione ")
      else
        @top_section.destroy
      end
    end

    respond_to do |format|
      format.html { redirect_to(top_sections_url) }
      format.xml { head :ok }
    end
  end
end

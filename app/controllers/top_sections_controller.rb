class TopSectionsController < ApplicationController
  layout 'admin'

  before_filter :require_admin

  helper :sort
  include SortHelper

#     sort_init 'last_name'
#     sort_update %w(first_name last_name)
#                'activity' => 'activity_id',
#                'project' => "#{Project.table_name}.name",
#     @contact_pages, @items = paginate :contacts,
#       :order_by => sort_clause,
#       :per_page => 10
#   end
#
# View (table header in list.rhtml):
#
#   <thead>
#     <tr>
#       <%= sort_header_tag('id', :title => 'Sort by contact ID') %>
#       <%= sort_header_tag('last_name', :caption => 'Name') %>
#       <%= sort_header_tag('phone') %>
#       <%= sort_header_tag('address', :width => 200) %>

  # GET /top_sections
  # GET /top_sections.xml
  def index
    #@top_sections = TopSection.all

    #Sorting
    sort_init 'sezione_top'
    sort_update 'sezione_top' => 'sezione_top',
                'ordinamento' => 'ordinamento',
                'style' => 'ordinamento',
                'se_visible' => 'se_visible'


#    @top_sections = TopSection.all
#    @top_section_pages, @items = paginate :top_sections,
#           :order_by => sort_clause,
#           :per_page => 2

    respond_to do |format|
      #ovverride for paging format.html # index.html.erb
      format.html {
        # Paginate results
        #@top_section_count = TimeEntry.visible.count(:include => [:project, :issue], :conditions => cond.conditions)
        @top_section_count = TopSection.all.count
        @top_section_pages = Paginator.new self, @top_section_count, per_page_option, params['page']
        @top_sections = TopSection.find(:all,
                                  :order => sort_clause,
                                  :limit  =>  @top_section_pages.items_per_page,
                                  :offset =>  @top_section_pages.current.offset)
#                                  :conditions => cond.conditions,
#                                  :include => [:project, :activity, :user, {:issue => :tracker}],

        render :layout => !request.xhr?
      }
      format.xml  { render :xml => @top_sections }
    end
  end

  # GET /top_sections/1
  # GET /top_sections/1.xml
  def show
    @top_section = TopSection.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @top_section }
    end
  end

  # GET /top_sections/new
  # GET /top_sections/new.xml
  def new
    @top_section = TopSection.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @top_section }
    end
  end

  # GET /top_sections/1/edit
  def edit
    @top_section = TopSection.find(params[:id])
#    @board.safe_attributes = params[:board]
#    if request.post? && @board.save
#      redirect_to_settings_in_projects
#    end
  end

  # POST /top_sections
  # POST /top_sections.xml
  def create
    @top_section = TopSection.new(params[:top_section])

    respond_to do |format|
      if @top_section.save
        format.html { redirect_to(@top_section, :notice => 'TopSection was successfully created.') }
        format.xml  { render :xml => @top_section, :status => :created, :location => @top_section }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @top_section.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /top_sections/1
  # PUT /top_sections/1.xml
  def update
    @top_section = TopSection.find(params[:id])

    respond_to do |format|
      if @top_section.update_attributes(params[:top_section])
        format.html { redirect_to(@top_section, :notice => 'TopSection was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @top_section.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /top_sections/1
  # DELETE /top_sections/1.xml
  def destroy
    @top_section = TopSection.find(params[:id])
    @top_section.destroy

    respond_to do |format|
      format.html { redirect_to(top_sections_url) }
      format.xml  { head :ok }
    end
  end
end

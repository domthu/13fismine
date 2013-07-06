class CrossGroupsController < ApplicationController
  layout 'admin'

  before_filter :require_admin

  helper :sort
  include SortHelper

  # GET /cross_groups
  # GET /cross_groups.xml
  def index
    #@cross_groups = CrossGroup.all

    #Sorting
    sort_init 'convention'
    sort_update 'id' => 'id',
                'convention' => "conventions.ragione_sociale",   #related table.Field
                'group banner' => "group_banners.espositore",   #related table.Field
                'se_visibile' => 'cross_groups.se_visibile'


    respond_to do |format|
      #ovverride for paging format.html # index.html.erb
      format.html {
        # Paginate results
        @cross_group_count = CrossGroup.all.count
        @cross_group_pages = Paginator.new self, @cross_group_count, per_page_option, params['page']
        @cross_groups = CrossGroup.find(:all,
                                  :order => sort_clause,
                                  :limit  =>  @cross_group_pages.items_per_page,
                                  :include => [:convention, :group_banner],
                                  :offset =>  @cross_group_pages.current.offset)
        render :layout => !request.xhr?
      }
      format.xml  { render :xml => @cross_groups }
    end
  end

  # GET /cross_groups/1
  # GET /cross_groups/1.xml
  def show
    @cross_group = CrossGroup.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @cross_group }
    end
  end

  # GET /cross_groups/new
  # GET /cross_groups/new.xml
  def new
    @cross_group = CrossGroup.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @cross_group }
    end
  end

  # GET /cross_groups/1/edit
  def edit
    @cross_group = CrossGroup.find(params[:id])
  end

  # POST /cross_groups
  # POST /cross_groups.xml
  def create
    @cross_group = CrossGroup.new(params[:cross_group])

    respond_to do |format|
      if @cross_group.save
        format.html { redirect_to(@cross_group, :notice => l(:notice_successful_create)) }
        format.xml  { render :xml => @cross_group, :status => :created, :location => @cross_group }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @cross_group.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /cross_groups/1
  # PUT /cross_groups/1.xml
  def update
    @cross_group = CrossGroup.find(params[:id])

    respond_to do |format|
      if @cross_group.update_attributes(params[:cross_group])
        format.html { redirect_to(@cross_group, :notice => l(:notice_successful_update)) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @cross_group.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /cross_groups/1
  # DELETE /cross_groups/1.xml
  def destroy
    @cross_group = CrossGroup.find(params[:id])
    @cross_group.destroy

    respond_to do |format|
      format.html { redirect_to(cross_groups_url) }
      format.xml  { head :ok }
    end
  end
end

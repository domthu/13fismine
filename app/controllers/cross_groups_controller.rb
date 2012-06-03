class CrossGroupsController < ApplicationController
  layout 'admin'

  before_filter :require_admin

  # GET /cross_groups
  # GET /cross_groups.xml
  def index
    @cross_groups = CrossGroup.all

    respond_to do |format|
      format.html # index.html.erb
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
        format.html { redirect_to(@cross_group, :notice => 'CrossGroup was successfully created.') }
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
        format.html { redirect_to(@cross_group, :notice => 'CrossGroup was successfully updated.') }
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

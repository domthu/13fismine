class ProvincesController < ApplicationController
  layout 'admin'
  helper :sort
  include SortHelper
  before_filter :require_admin
  before_filter :set_menu
  menu_item :provinces
  def set_menu
    @menu_fs = :menu_comuni
  end
  # GET /provinces
  # GET /provinces.xml
  def index
    #Sorting
    sort_init 'provincia'
    sort_update 'provincia' => 'provinces.name',
                'regione' => "regions.name"

    @provinces = Province.find(:all, :include => :region ,:order => sort_clause )

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @provinces }
    end
  end

  # GET /provinces/1
  # GET /provinces/1.xml
  def show
    @province = Province.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @province }
    end
  end

  # GET /provinces/new
  # GET /provinces/new.xml
  def new
    @province = Province.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @province }
    end
  end

  # GET /provinces/1/edit
  def edit
    @province = Province.find(params[:id])
  end

  # POST /provinces
  # POST /provinces.xml
  def create
    @province = Province.new(params[:province])

    respond_to do |format|
      if @province.save
        format.html { redirect_to(@province, :notice => l(:notice_successful_create)) }
        format.xml  { render :xml => @province, :status => :created, :location => @province }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @province.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /provinces/1
  # PUT /provinces/1.xml
  def update
    @province = Province.find(params[:id])

    respond_to do |format|
      if @province.update_attributes(params[:province])
        format.html { redirect_to(@province, :notice => l(:notice_successful_update)) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @province.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /provinces/1
  # DELETE /provinces/1.xml
  def destroy
    @province = Province.find(params[:id])
    @province.destroy

    respond_to do |format|
      format.html { redirect_to(provinces_url) }
      format.xml  { head :ok }
    end
  end
end

class GroupBannersController < ApplicationController
  layout 'admin'

  before_filter :require_admin

  # GET /group_banners
  # GET /group_banners.xml
  def index
    @group_banners = GroupBanner.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @group_banners }
    end
  end

  # GET /group_banners/1
  # GET /group_banners/1.xml
  def show
    @group_banner = GroupBanner.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @group_banner }
    end
  end

  # GET /group_banners/new
  # GET /group_banners/new.xml
  def new
    @group_banner = GroupBanner.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @group_banner }
    end
  end

  # GET /group_banners/1/edit
  def edit
    @group_banner = GroupBanner.find(params[:id])
  end

  # POST /group_banners
  # POST /group_banners.xml
  def create
    @group_banner = GroupBanner.new(params[:group_banner])

    respond_to do |format|
      if @group_banner.save
        format.html { redirect_to(@group_banner, :notice => l(:notice_successful_create)) }
        format.xml  { render :xml => @group_banner, :status => :created, :location => @group_banner }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @group_banner.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /group_banners/1
  # PUT /group_banners/1.xml
  def update
    @group_banner = GroupBanner.find(params[:id])

    respond_to do |format|
      if @group_banner.update_attributes(params[:group_banner])
        format.html { redirect_to(@group_banner, :notice => l(:notice_successful_update)) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @group_banner.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /group_banners/1
  # DELETE /group_banners/1.xml
  def destroy
    @group_banner = GroupBanner.find(params[:id])
    @group_banner.destroy

    respond_to do |format|
      format.html { redirect_to(group_banners_url) }
      format.xml  { head :ok }
    end
  end
end

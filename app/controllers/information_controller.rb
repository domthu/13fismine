class InformationController < ApplicationController
  # GET /information
  # GET /information.xml
  def index
    @information = Information.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @information }
    end
  end

  # GET /information/1
  # GET /information/1.xml
  def show
    @information = Information.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @information }
    end
  end

  # GET /information/new
  # GET /information/new.xml
  def new
    @information = Information.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @information }
    end
  end

  # GET /information/1/edit
  def edit
    @information = Information.find(params[:id])
  end

  # POST /information
  # POST /information.xml
  def create
    @information = Information.new(params[:information])

    respond_to do |format|
      if @information.save
        format.html { redirect_to(@information, :notice => 'Information was successfully created.') }
        format.xml  { render :xml => @information, :status => :created, :location => @information }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @information.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /information/1
  # PUT /information/1.xml
  def update
    @information = Information.find(params[:id])

    respond_to do |format|
      if @information.update_attributes(params[:information])
        format.html { redirect_to(@information, :notice => 'Information was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @information.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /information/1
  # DELETE /information/1.xml
  def destroy
    @information = Information.find(params[:id])
    @information.destroy

    respond_to do |format|
      format.html { redirect_to(information_url) }
      format.xml  { head :ok }
    end
  end
end

class ComunesController < ApplicationController
  layout 'admin'

  before_filter :require_admin

  # GET /comunes
  # GET /comunes.xml
  def index
    @comunes = Comune.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @comunes }
    end
  end

  # GET /comunes/1
  # GET /comunes/1.xml
  def show
    @comune = Comune.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @comune }
    end
  end

  # GET /comunes/new
  # GET /comunes/new.xml
  def new
    @comune = Comune.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @comune }
    end
  end

  # GET /comunes/1/edit
  def edit
    @comune = Comune.find(params[:id])
  end

  # POST /comunes
  # POST /comunes.xml
  def create
    @comune = Comune.new(params[:comune])

    respond_to do |format|
      if @comune.save
        format.html { redirect_to(@comune, :notice => l(:notice_successful_create)) }
        format.xml  { render :xml => @comune, :status => :created, :location => @comune }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @comune.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /comunes/1
  # PUT /comunes/1.xml
  def update
    @comune = Comune.find(params[:id])

    respond_to do |format|
      if @comune.update_attributes(params[:comune])
        format.html { redirect_to(@comune, :notice => l(:notice_successful_update)) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @comune.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /comunes/1
  # DELETE /comunes/1.xml
  def destroy
    @comune = Comune.find(params[:id])
    @comune.destroy

    respond_to do |format|
      format.html { redirect_to(comunes_url) }
      format.xml  { head :ok }
    end
  end
end

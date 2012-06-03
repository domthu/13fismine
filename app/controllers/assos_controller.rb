class AssosController < ApplicationController
  layout 'admin'

  before_filter :require_admin

  # GET /assos
  # GET /assos.xml
  def index
    @assos = Asso.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @assos }
    end
  end

  # GET /assos/1
  # GET /assos/1.xml
  def show
    @asso = Asso.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @asso }
    end
  end

  # GET /assos/new
  # GET /assos/new.xml
  def new
    @asso = Asso.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @asso }
    end
  end

  # GET /assos/1/edit
  def edit
    @asso = Asso.find(params[:id])
  end

  # POST /assos
  # POST /assos.xml
  def create
    @asso = Asso.new(params[:asso])

    respond_to do |format|
      if @asso.save
        format.html { redirect_to(@asso, :notice => 'Asso was successfully created.') }
        format.xml  { render :xml => @asso, :status => :created, :location => @asso }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @asso.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /assos/1
  # PUT /assos/1.xml
  def update
    @asso = Asso.find(params[:id])

    respond_to do |format|
      if @asso.update_attributes(params[:asso])
        format.html { redirect_to(@asso, :notice => 'Asso was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @asso.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /assos/1
  # DELETE /assos/1.xml
  def destroy
    @asso = Asso.find(params[:id])
    @asso.destroy

    respond_to do |format|
      format.html { redirect_to(assos_url) }
      format.xml  { head :ok }
    end
  end
end

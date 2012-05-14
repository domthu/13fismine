class TopSectionsController < ApplicationController
  # GET /top_sections
  # GET /top_sections.xml
  def index
    @top_sections = TopSection.all

    respond_to do |format|
      format.html # index.html.erb
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

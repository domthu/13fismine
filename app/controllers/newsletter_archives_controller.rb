class NewsletterArchivesController < ApplicationController
  # GET /newsletter_archives
  # GET /newsletter_archives.xml
  def index
    @newsletter_archives = NewsletterArchive.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @newsletter_archives }
    end
  end

  # GET /newsletter_archives/1
  # GET /newsletter_archives/1.xml
  def show
    @newsletter_archive = NewsletterArchive.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @newsletter_archive }
    end
  end

  # GET /newsletter_archives/new
  # GET /newsletter_archives/new.xml
  def new
    @newsletter_archive = NewsletterArchive.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @newsletter_archive }
    end
  end

  # GET /newsletter_archives/1/edit
  def edit
    @newsletter_archive = NewsletterArchive.find(params[:id])
  end

  # POST /newsletter_archives
  # POST /newsletter_archives.xml
  def create
    @newsletter_archive = NewsletterArchive.new(params[:newsletter_archive])

    respond_to do |format|
      if @newsletter_archive.save
        format.html { redirect_to(@newsletter_archive, :notice => 'NewsletterArchive was successfully created.') }
        format.xml  { render :xml => @newsletter_archive, :status => :created, :location => @newsletter_archive }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @newsletter_archive.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /newsletter_archives/1
  # PUT /newsletter_archives/1.xml
  def update
    @newsletter_archive = NewsletterArchive.find(params[:id])

    respond_to do |format|
      if @newsletter_archive.update_attributes(params[:newsletter_archive])
        format.html { redirect_to(@newsletter_archive, :notice => 'NewsletterArchive was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @newsletter_archive.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /newsletter_archives/1
  # DELETE /newsletter_archives/1.xml
  def destroy
    @newsletter_archive = NewsletterArchive.find(params[:id])
    @newsletter_archive.destroy

    respond_to do |format|
      format.html { redirect_to(newsletter_archives_url) }
      format.xml  { head :ok }
    end
  end
end

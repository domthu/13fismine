class ReservationsController < ApplicationController
  layout 'admin'

  before_filter :require_admin

  helper :sort
  include SortHelper

  # GET /reservations
  # GET /reservations.xml
  def reservations_to_pdf
    sort_init 'Utente', 'ASC'
    sort_update 'Utente' => 'users.lastname',
                'Login' => 'users.login',
                'N' => 'num_persone',
                'Provenienza' => 'comunes.name',
                'Tel' => 'users.telefono',
                'Id' => 'users.id'

    respond_to do |format|
      #ovverride for paging format.html # index.html.erb
      format.html {
        # Paginate results
        if params[:issue_id].present? && !params[:issue_id].nil?
          @reservations = Reservation.find(:all,
                                           :order => sort_clause,
                                           :include => [:issue, :user],
                                           :conditions => "issues.id = #{params[:issue_id]}"
          )

          @reservations_total = @reservations.sum { |itm| itm.num_persone } rescue 0
          @payments_total = @reservations.sum { |itm| itm.prezzo } rescue 0

        else

          @reservations = Reservation.find(:all,
                                           :order => sort_clause,
                                           :include => [{:issue => :project}, :user])
          render :layout => !request.xhr?

        end


      }
      format.xml { render :xml => @reservations }
    end
  end

  def download_pdf
    unless params[:issue_id].nil?
      html = render_to_string(:controller => 'reservations', :action => 'reservations_to_pdf', :issue_id => params[:issue_id], :layout => false)
      pdf = PDFKit.new(html)
      pdf.stylesheets << "#{Rails.root.to_s}/stylesheets/pdf_in.css"
      send_data(pdf.to_pdf)
    else
      flash[:error] = 'Nessun parametro passato... errore in reservation_controller action: download_pdf '
    end
  end

  def index
    #@reservations = Reservation.all
    #respond_to do |format|
    #  format.html # index.html.erb
    #  format.xml  { render :xml => @reservations }
    #end

    #Sorting
    sort_init 'issue'
    sort_update 'User' => 'users.login',
                'Issue' => 'issues.subject',
                'num_persone' => 'num_persone',
                'prezzo' => 'prezzo',
                'msg' => 'msg'

    respond_to do |format|
      #ovverride for paging format.html # index.html.erb
      format.html {
        # Paginate results
        @reservation_count = Reservation.all.count
        @reservation_pages = Paginator.new self, @reservation_count, per_page_option, params['page']
        @reservations = Reservation.find(:all,
                                         :order => sort_clause,
                                         :limit => @reservation_pages.items_per_page,
                                         :include => [{:issue => :project}, :user],
                                         :offset => @reservation_pages.current.offset)
        render :layout => !request.xhr?
      }
      format.xml { render :xml => @reservations }
    end
  end

  # GET /reservations/1
  # GET /reservations/1.xml
  def show
    @reservation = Reservation.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml { render :xml => @reservation }
    end
  end

  # GET /reservations/new
  # GET /reservations/new.xml
  def new
    @reservation = Reservation.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml { render :xml => @reservation }
    end
  end

  # GET /reservations/1/edit
  def edit
    @reservation = Reservation.find(params[:id])
  end

  # POST /reservations
  # POST /reservations.xml
  def create
    @reservation = Reservation.new(params[:reservation])

    respond_to do |format|
      if @reservation.save
        format.html { redirect_back_or_default home_url }
        #format.html { redirect_to(@reservation, :notice => 'Reservation was successfully created.') }
        format.xml { render :xml => @reservation, :status => :created, :location => @reservation }
      else
        format.html { render :action => "new" }
        format.xml { render :xml => @reservation.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /reservations/1
  # PUT /reservations/1.xml
  def update
    @reservation = Reservation.find(params[:id])

    respond_to do |format|
      if @reservation.update_attributes(params[:reservation])
        format.html { redirect_to(@reservation, :notice => 'Reservation was successfully updated.') }
        format.xml { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml { render :xml => @reservation.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /reservations/1
  # DELETE /reservations/1.xml
  def destroy
    @reservation = Reservation.find(params[:id])
    @reservation.destroy

    respond_to do |format|
      format.html { redirect_to(reservations_url) }
      format.xml { head :ok }
    end
  end
end

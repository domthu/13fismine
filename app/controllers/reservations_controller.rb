
class ReservationsController < ApplicationController
   # GET /reservations
  # GET /reservations.xml
  def index
    @reservations = Reservation.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @reservations }
    end
  end

  # GET /reservations/1
  # GET /reservations/1.xml
  def show
    @reservation = Reservation.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @reservation }
    end
  end

  # GET /reservations/new
  # GET /reservations/new.xml
  def new
    @reservation = Reservation.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @reservation }
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
        back_url = CGI.unescape(params[:back_url].to_s)
        if !back_url.blank?
          begin
            uri = URI.parse(back_url)
            # do not redirect user to another host or to the login or register page
            if (uri.relative? || (uri.host == request.host)) && !uri.path.match(%r{/(login|account/register)})
              redirect_to(back_url)
              return
            end
          rescue URI::InvalidURIError
            # redirect to default
          end
        else
          redirect_to default
        end
         #redirect_back_or_default({:controller => 'reservation', :action => 'show', :id => @reservation.id})
        #format.html { redirect_to(@reservation, :notice => 'Reservation was successfully created.') }
        #format.xml  { render :xml => @reservation, :status => :created, :location => @reservation }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @reservation.errors, :status => :unprocessable_entity }
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
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @reservation.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /reservations/1
  # DELETE /reservations/1.xml
  def destroy
    @reservation = Reservation.find(params[:id])
    @reservation.destroy

    respond_to do |format|

      format.html {
        redirect_back_or_default reservations_url
      }
      #format.html { redirect_to(reservations_url) }
      format.xml  { head :ok }
    end
  end
end

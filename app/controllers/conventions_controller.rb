class ConventionsController < ApplicationController
  layout 'admin'

  before_filter :require_admin

  helper :sort
  include SortHelper
  include ApplicationHelper
  include FeeConst

  menu_item :conventions
  before_filter :set_menu

  def set_menu
    @menu_fs = :menu_fiscosport
  end

  # GET /conventions
  # GET /conventions.xml
  def index
    #@convs = Convention.all

    #Sorting
    sort_init 'data_scadenza DESC'
    sort_update 'ragione_sociale' => 'ragione_sociale',
                'email' => 'email',
                'indirizzo' => "indirizzo",
                'presidente' => 'presidente',
                'referente' => 'referente',
                'consulente' => 'consulente',
                'logo' => 'logo',
                'telefono' => 'telefono',
                'fax' => 'fax',
                'Tipo_Sigla' => 'type_organizations.tipo, cross_organizations.sigla', #related table.Field
                'regione' => 'regions.name', #related table.Field
                'province' => 'provinces.name', #related table.Field
                'comune' => 'comunes.name', #related table.Field
                'responsabile' => 'users.firstname, users.lastname', #related table.Field
                'scadenza' => 'data_scadenza',
                'ConiNum?' => 'richiedinumeroregistrazione'

    respond_to do |format|
      #ovverride for paging format.html # index.html.erb
      format.html {
        @convs = Convention.find(:all,
                                 :order => sort_clause,
                                 :include => [:province, :comune, :user, {:cross_organization => [:type_organization]}]
        )
        render :layout => !request.xhr?
      }
      format.xml { render :xml => @convs }
    end
  end

  def show
    @conv = Convention.find(params[:id])
    if params[:uprole].present? && !params[:uprole].blank?
      @uprole = params[:uprole]
    end
    respond_to do |format|
      format.html # show.html.erb
      format.xml { render :xml => @conv }
    end
  end

  def new
    @conv = Convention.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml { render :xml => @conv }
    end
  end

  # GET /conventions/1/edit
  def edit
    #@conv = Convention.find(params[:id], :include => [:user])
    @conv = Convention.find(params[:id])
  end

  # POST /conventions
  # POST /conventions.xml
  def create
    @conv = Convention.new(params[:convention])
    if (!@conv.codice_attivazione.empty?)
      @conv.codice_attivazione = @conv.codice_attivazione.downcase!
    end
    respond_to do |format|
      if @conv.save

        #Control eventuali convenzionati
        control_conv(@conv)

        format.html { redirect_to(@conv, :notice => l(:notice_successful_create)) }
        format.xml { render :xml => @conv, :status => :created, :location => @conv }
      else
        format.html { render :action => "new" }
        format.xml { render :xml => @conv.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /conventions/1
  # PUT /conventions/1.xml
  def update
    @conv = Convention.find(params[:id])
    s = ""
    respond_to do |format|
      if @conv.update_attributes(params[:convention])
        #update all federati
        @conv.users.each do |usr|
          role_old = usr.role_id
          usr.control_state
          if role_old != usr.role_id
            s += "<br /><b style='color: red;'>Controllato</b> "+ usr.name + "#" + usr.id.to_s + " da ruolo: " + get_abbonamento_name(role_old) + "  a:  " + get_abbonamento_name(usr.role_id)
            # send_warning("<b style='color: red;'>Controllato utente</b> "+ usr.name + "(" + usr.id.to_s + ") da ruolo (" + get_abbonamento_name(role_old) + "  --> " + get_abbonamento_name(usr.role_id) + ")")
          else
            s += "<br /><b style='color: green;'>Controllato</b> "+ usr.name + "#" + usr.id.to_s + " assegnato ruolo: " + get_abbonamento_name(usr.role_id)
            # send_warning("<b style='color: green;'>Controllato utente</b> "+ usr.name + "(" + usr.id.to_s + ") di ruolo (" + get_abbonamento_name(usr.role_id) + ")")
          end
        end
        #send_warning(s)    #sandro : tolto perchè causa errore di cookie
        #Control eventuali convenzionati
        control_conv(@conv)
        format.html { redirect_to :controller => 'conventions', :action => 'show', :id => @conv, :uprole => s }
        # format.html { redirect_to(@conv, :notice => l(:notice_successful_update) ,:uprole => params[@s] ) }
        format.xml { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml { render :xml => @conv.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /conventions/1
  # DELETE /conventions/1.xml
  def destroy
    @conv = Convention.find(params[:id])
    @conv.destroy

    @user = User.all(:conditions => {:convention_id => params[:id]})
    @user.each do |usr|
      # sandro rimosso il send_warning per errore di cookie
      #send_warning(msg + "<b style='color: green;'>Tolto con per utente</b> "+ usr.name + "(" + usr.id.to_s + ") di ruolo (" + get_abbonamento_name(usr.role_id) + ")")
      usr.convention_id = nil
      usr.save! #--> save_without_transactions
      usr.control_state
    end

    respond_to do |format|
      format.html { redirect_to(conventions_url) }
      format.xml { head :ok }
    end
  end

  private

  def control_conv(_conv)
    return
    #STEP1/2 find susceptible federati by zone
    if (!_conv.codice_attivazione.nil? && !_conv.codice_attivazione.blank?)
      @user = User.all(:conditions => ["LOWER(codice_attivazione)=?", _conv.codice_attivazione])
      @user.each do |usr|
        add_to_conv(usr, _conv, "Da code att. ")
      end
    end
    #STEP2/2 find susceptible federati by zone
    #@user = User.all(:conditions => {:cross_organization_id => _conv.cross_organization_id})
    @user = User.all(:conditions => ["comune_id is not null AND cross_organization_id is not null AND cross_organization_id=?", _conv.cross_organization_id])
    if _conv.region_id && _conv.region
      @Conv_Comuni_By_region = Province.find(:all, :include => [:comunes], :conditions => ["provinces.region_id=?", _conv.region_id]).collect { |u| [u.comunes.id] }
    end
    if _conv.province_id && _conv.province
      @Conv_Comuni_By_province = Comune.find(:all, :conditions => ["province_id=?", _conv.province_id]).collect { |u| [u.id] }
    end
    @user.each do |usr|
      #control if user.scadenza < conv.scadenza
      if ((_conv.scadenza.is_a?(Date)) && (usr.scadenza.nil? || (usr.scadenza < _conv.scadenza)))
        #control if user is in geografical zone
        isInZone = false
        if _conv.province.nil? #iniziare dalla provincia
          if _conv.region.nil?
            #Nazionale
            isInZone = true
          else
            if @Conv_Comuni_By_region && (@Conv_Comuni_By_region.count > 0)
              #Regionale
              #haveTownInRegion = Province.find(:all, :include => [:comunes], :conditions => ["comunes.id=? AND provinces.region_id=?", usr.comune_id, _conv.region_id]).count
              if @Conv_Comuni_By_region.count(:conditions => ["id=?", usr.comune_id]) > 0
                isInZone = true
              end
            end
          end
        else
          if @Conv_Comuni_By_province && (@Conv_Comuni_By_province.count > 0)
            #Provinciale
            #haveTownInProvince = Comune.find(:all, :conditions => ["id=? AND province_id=?", usr.comune_id, _conv.province_id]).count
            if @Conv_Comuni_By_province.count(:conditions => ["id=?", usr.comune_id]) > 0
              isInZone = true
            end
          end
        end
        if (isInZone == true)
          add_to_conv(usr, _conv, "Da zona-fede. ")
        end
      end #scadenza
    end #each user
  end

  def add_to_conv(usr, _conv, msg)
    return
    #ruoli sottoposti alla gestione abboanmento
    if (usr.convention_id) && (usr.convention_id == _conv.id)
      return
    elsif (FeeConst::FEE_ROLES.include? usr.role_id)
      if (usr.isarchivied?)
        send_error(msg + "<b style='color: red;'>Utente archiviato che corrispondeva</b> "+ usr.name + "(" + usr.id.to_s + ")")
      else
        if (usr.convention_id)
          send_warning(msg + "<b style='color: red;'>Sostituito conv per utente</b> "+ usr.name + "(" + usr.id.to_s + ") di ruolo (" + get_abbonamento_name(usr.role_id) + ") con ex-convention: " + usr.convention.name + " --> " + usr.convention.pact)
        else
          send_warning(msg + "<b style='color: green;'>Aggiunto utente</b> "+ usr.name + "(" + usr.id.to_s + ") di ruolo (" + get_abbonamento_name(usr.role_id) + ")")
        end

        usr.convention_id = _conv.id
        usr.save! #--> save_without_transactions
        usr.control_state
      end
    end
  end

end

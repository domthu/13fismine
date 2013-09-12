# Redmine - project management software
# Copyright (C) 2006-2011  Created by  DomThual & SPecchiaSoft (2013)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

class AccountController < ApplicationController
  layout 'editorial'
  helper :custom_fields
  include CustomFieldsHelper
  include FeesHelper #ROLE_XXX  gedate
  before_filter :reroute_if_logged, :only => :register

  # prevents login action to be filtered by check_if_login_required application scope filter
  skip_before_filter :check_if_login_required

  # Login request and validation
  def login
    #Rails.logger.info("login PARAMS: #{params.inspect}")
    #flash[:notice] = "==========login============="
    if request.get?
      #flash[:notice] = "request.get --> logout_user"
      logout_user
    else
      authenticate_user
    end
  end

  # Log out current user and redirect to welcome page
  def logout
    logout_user
    #domthu redirect_to home_url
    redirect_to editorial_url
  end

  # Enable user to choose a new password
  def lost_password
    #domthu redirect_to(home_url) && return unless Setting.lost_password?
    redirect_to(editorial_url) && return unless Setting.lost_password?
    if params[:token]
      @token = Token.find_by_action_and_value("recovery", params[:token])
      #redirect_to(home_url) && return unless @token and !@token.expired?
      redirect_to(editorial_url) && return unless @token and !@token.expired?
      @user = @token.user
      if request.post?
        @user.password, @user.password_confirmation = params[:new_password], params[:new_password_confirmation]
        if @user.save
          @token.destroy
          flash[:notice] = l(:notice_account_password_updated)
          redirect_to editorial_url
          return
        end
      end
      render :template => "account/password_recovery"
      return
    else
      if request.post?
        user = User.find_by_mail(params[:mail])
        user = User.find_by_login(params[:mail]) unless user
        # user not found in db
        (flash.now[:error] = l(:notice_account_unknown_email); return) unless user
        # user uses an external authentification
        (flash.now[:error] = l(:notice_can_t_change_password); return) if user.auth_source_id
        # create a new token for password recovery
        token = Token.new(:user => user, :action => "recovery")
        if token.save
          Mailer.deliver_lost_password(token)
          flash[:notice] = l(:notice_account_lost_email_sent)
          redirect_to  :back
          return
        end
      end
    end
  end

#Parameters: {"extra_town"=>"7289", "action"=>"register", "commit"=>"Invia", "authenticity_token"=>"oE/I9wEZXoXqA0iRUM+BS+fbprZFzqmGoCtdOhzN0hY=", "controller"=>"account", "user"=>{"codice_attivazione"=>"", "password"=>"[FILTERED]", "firstname"=>"dom7", "se_privacy"=>"1", "language"=>"it", "se_condition"=>"1", "fax"=>"", "indirizzo"=>"", "partitaiva"=>"", "soc"=>"", "password_confirmation"=>"[FILTERED]", "mail"=>"dom_thual@yahoo.it", "comune_id"=>"7289", "login"=>"dom7", "cross_organization_id"=>"1", "telefono"=>"", "codicefiscale"=>"thlddj", "titolo"=>"Tecnico/Dirigente", "lastname"=>"thual7"}}
  def register
    redirect_to(editorial_url) && return unless Setting.self_registration? || session[:auth_source_registration]
    if request.get?
      session[:auth_source_registration] = nil
      @user = User.new(:language => Setting.default_language)
    else
      @user = User.new(params[:user])
      @user.safe_attributes = params[:user]
      @user.admin = false
      #default role_id
      @user.role_id = FeeConst::ROLE_REGISTERED
      #Collect fs custom data
      @user.pwd = params[:user][:password]
      if params[:user][:se_condition].present?
        @user.se_condition = params[:user][:se_condition]
      else
        flash.now[:error] = l(:notice_register_must_condition);
        return
      end
      if params[:user][:se_privacy].present?
        @user.se_privacy = params[:user][:se_privacy]
      else
        flash.now[:error] = l(:notice_register_must_consensus);
        return
      end

      #Region Province Comune from select2 onto extra_town
      #set user_comune_id at run time in FormatCitta
      if params[:user][:comune_id].present?
        @user.comune_id = params[:user][:comune_id].to_i
        if Comune.exists?(@user.comune_id)
          @user.comune = Comune.find(:first, :include => [[ :province => :region ]], :conditions => ['id =  ?', @user.comune_id.to_s])
          if @user.comune #province_id region_id	cap
            @user.cap = @user.comune.cap
            @user.prov = @user.comune.province.name_full unless @user.comune.province.nil?
            @user.prov += @user.comune.province.region.name unless ( @user.comune.province.nil? && @user.comune.region.province.nil?)
          else
            @user.comune_id = nil
          end
        else
          @user.comune_id = nil
        end
      end
      if @user.comune_id.nil?
        #send_warning("Città di attività sportiva non presente. E importante inserirla in quanto potrebbe appartenire ad una zona coperta da un accordo convenzionato.")
      end
      if (params[:user][:cross_organization_id])
        @user.cross_organization_id = params[:user][:cross_organization_id].to_i
        if CrossOrganization.exists?(@user.cross_organization_id)
          @user.cross_organization = CrossOrganization.find(:first, :conditions => ['id =  ?', @user.cross_organization_id.to_s])
          if @user.cross_organization
            @user.cross_organization_id = @user.cross_organization.id
          else
            @user.cross_organization_id = nil
          end
        else
          @user.cross_organization_id = nil
        end
      end

      #STEP3 CONI FSN e convenzione
      @user.datascadenza = Date.today + Setting.register_days.to_i
      if params[:user][:codice_attivazione].present?
        @user.codice_attivazione = params[:user][:codice_attivazione].to_s.downcase
        @user.convention = Convention.find(:first, :conditions => ['LOWER(codice_attivazione) =  ?', @user.codice_attivazione])
        if @user.convention
          send_notice("Codice di attivazione valido per " + @user.convention.name)
          send_notice("Copertura della convenzione: " + @user.convention.pact)
          @user.convention_id = @user.convention.id
        else
          send_warning("Il codice di attivazione non corrisponde ad nessuna convenzione.")
        end
      end

      if @user.comune && @user.cross_organization && @user.convention_id.nil?
        #ricerca copertura di una convention?
        if @user.cross_organization.conventions.any?
          #ciclo su ogni convention
          migliorScadenza = @user.datascadenza
          @user.cross_organization.conventions.find(:all, :order => ' province_id DESC , region_id DESC , data_scadenza DESC').each do |conv|
            neFaParte = false
            #controllare su quale copertura
            if conv.province.nil? #|| conv.province_id == 0#iniziare dalla provincia
              if conv.region.nil?
                #Nazionale
                neFaParte = true
              else
                #Regionale
                neFaParte = (@user.comune.province.region == conv.region)
              end
            else
              #Provinciale
              neFaParte = (@user.comune.province == conv.province)
            end
            if neFaParte == true
              #la prima volta assegno la convention_id
              send_notice("Lei risulta essere coperto da: " + conv.name)
              send_notice("Copertura della convenzione: " + conv.pact)
              if @user.convention_id.nil?
                @user.convention_id = conv.id
                @user.convention = conv
                break # esco alla prima che trovo
              end
              #il non pagante prenderà la scadenza della convenzione
              if conv.scadenza && (conv.scadenza > migliorScadenza)
                migliorScadenza = conv.scadenza
                if @user.convention_id != conv.id
                  #questa convenzione e migliore di quella dapprima
                  @user.convention_id = conv.id
                  @user.convention = conv
                end
              end
              #break per uscire --> No, continuo per vedere se c'è una convention migliore
            end
          end  #ciclo sulle conventions
          if !@user.convention_id.nil?
            @user.datascadenza = migliorScadenza
            @user.datascadenza = nil #Non pagante
          end
        end
      end

      #end
      if (params[:user][:mail])
        @user.mail_fisco = params[:user][:mail]
      end

      #Gestione ruoli
      if Setting.fee?
        @user.annotazioni = "" unless !@user.annotazioni.nil?
        #impostazioni minimali di default
        @user.datascadenza = Date.today + Setting.register_days.to_i
        @user.role_id = FeeConst::ROLE_REGISTERED
        # se dichiara di essere convenzionato
        if @user.convention_id
          conv = Convention.find_by_id(@user.convention_id)
          if conv.nil?
            @user.annotazioni = "<br />REGISTER(da sistema): l'utente risulta far parte della convention(" + @user.convention_id.to_s + " che non esiste"
            @user.convention_id = nil
          else
            #@user.datascadenza = conv.scadenza
            @user.datascadenza = nil
            @user.role_id = conv.role_id  # ruolo elaborato in funzione dello stato della scadenza
          end
        end
      end

      @user.register

      if session[:auth_source_registration]
        @user.activate
        @user.login = session[:auth_source_registration][:login]
        @user.auth_source_id = session[:auth_source_registration][:auth_source_id]

#        if @user.save
#          session[:auth_source_registration] = nil
#          self.logged_user = @user
#          flash[:notice] = l(:notice_account_activated)
#          #redirect_to :controller => 'my', :action => 'account'
#          redirect_to my_profile_show_url
#        end
      else
        @user.login = params[:user][:login]
        @user.password, @user.password_confirmation = params[:user][:password], params[:user][:password_confirmation]
        #@user.password, @user.password_confirmation = params[:password], params[:password_confirmation]

        case Setting.self_registration
          when '1'
            register_by_email_activation(@user)
          when '3'
            register_automatically(@user)
          else
            register_manually_by_administrator(@user)
        end
      end
    end
  end

  #via js
  def prova
    #FeeConst::ROLE_REGISTERED     = 9  #Ospite periodo di prova durante Setting.register_days<br />
    @user = User.new(:language => Setting.default_language, :mail_notification => Setting.default_notification_option)
    @user.admin = false
    @user.mail = params[:mail] if params[:mail].present?
    @user.firstname = params[:firstname] if params[:firstname].present?
    @user.lastname = params[:lastname] if params[:lastname].present?
    @user.login = @user.mail
    @user.comune_id = 1
    @user.random_password #    self.password = password & self.password_confirmation = password
    @user.se_condition = true
    @user.se_privacy = true
                          #default role_id
    @user.role_id = FeeConst::ROLE_REGISTERED
    @user.datascadenza = Date.today + Setting.register_days.to_i
                          #@user.mail_notification = 'selected'
                          #@user.mail_notification = 'only_my_events'
    @user.annotazioni = "Prova gratis per " + @user.name + ", con email " + @user.mail + ", fatta il " + Date.today.to_s + ", per " + Setting.register_days.to_s + " giorni. Scadenza: " + @user.scadenza.to_s

    @stat =''
    @errors = ''
    if !@user.valid?
      if !@user.errors.empty?
        #@errors += @user.errors.join(', ') undefined method join
        @errors += "Errore incontrate: " + @user.errors.full_messages.join('<br />')
      end
      #puts "********************Prova user not valid (" + @errors + ")********************"
      #format.html { return redirect_to :controller => 'editorial', :action => 'prova', :user => @user }
      #format.js {
      return render :json => {
          :success => false,
          :response => @stat,
          :errors => @errors
      }
      #}
    end

    @user.register

    raise_delivery_errors = ActionMailer::Base.raise_delivery_errors
    # Force ActionMailer to raise delivery errors so we can catch it
    ActionMailer::Base.raise_delivery_errors = true
    @stat = "Tipo registrazione(" + Setting.self_registration + "). "
    begin
      case Setting.self_registration
        when '1'
          @stat += " Utente registrato, in attesa della conferma email"
          #register_by_email_activation(@user)
          token = Token.new(:user => @user, :action => "register")
          if @user.save and token.save
            Mailer.deliver_register(token)
            @stat = "Email inviata correttamente: <br /><strong>Verifichi la sua casella postale e confermi la sua email</strong>"
            @stat += l(:notice_account_register_done)
          else
            @stat += " Errore nella procedura di conferam email: <span style='color: red; font-weight: bolder;'>Utente NON registrato e quindi nessuna email di conferma inviata</span>"
          end

        when '3' # Automatic activation
          @stat += " Utente registrato automaticamente"
          #register_automatically(@user)
          @user.activate
          @user.last_login_on = Time.now
          if @user.save
            self.logged_user = @user
            @stat = l(:notice_account_activated)
            Mailer.deliver_account_information(user, user.pwd)
            tmail = Mailer.deliver_fee(user, 'thanks', Setting.template_fee_thanks)
          else
            @stat += " Errore nella creazione automatica: <span style='color: red; font-weight: bolder;'> Utente NON registrato automaticamente. Riprovare</span>"
          end

        else
          @stat += " Utente NON registrato: richiede registrazione manuale da parte dell'amministratore"
          #register_manually_by_administrator(@user)
          if @user.save
            # Sends an email to the administrators
            Mailer.deliver_account_activation_request(user)
            account_pending
            @stat += "Registrazione effettuata: <br /><strong>In attesa di abilitazione utente</strong>"
          else
            @stat += " Creazione manuale da Admin: <span style='color: red; font-weight: bolder;'>Utente NON registrato e quindi l'amministratore deve fare una registrazione manuale</span>"
          end

        if !@user.errors.empty?
          @errors += "<br />errore completa: " + @user.errors.full_messages.join('<br />')
        end
      end
      htmlpartial = ''
      @tmail = Mailer.deliver_prova_gratis(@user, @stat + "<br />" + htmlpartial)
    rescue Exception => e
      @errors += "<span style='color: red;'>" + l(:notice_email_error, e.message) + "</span>"
    end
    ActionMailer::Base.raise_delivery_errors = raise_delivery_errors

    #prototype
    #respond_to do |format|
    #    format.js {
    #      render(:update) {|page|
    #       page.replace_html "user-response", @stat
    #        page.alert(@stat)
    #      }
    #    }
    #end
    #Jquery
    if (!@errors.nil? and @errors.length > 0)
      return render :json => {
          :success => false,
          :response => @stat,
          :errors => @errors
      }
    else
      render :json => {
          :success => true,
          :response => @stat,
          :errors => "errore: " + @errors}
    end
  end

  #unused double render in prova
  def getuserhtml(user)
    render_to_string(
        :layout => false,
        :controller => 'user',
        :action => 'show',
        :locals => {:user => user}
    )
    #  :partial => 'user/show',
  end

  #email confermazione Inviare la password
  # Token based account activation
  def activate
    #domthu redirect_to(home_url) && return unless Setting.self_registration? && params[:token]
    redirect_to(editorial_url) && return unless Setting.self_registration? && params[:token]
    token = Token.find_by_action_and_value('register', params[:token])
    if token && token.user
      user = token.user
      #domthu redirect_to(home_url) && return unless user.registered?
      redirect_to(editorial_url) && return unless user.registered?
      user.activate
      if user.save
        token.destroy
        flash[:notice] = l(:notice_account_activated)
        #in caso di prova gratis inviare dati di accesso
        if (user.pwd && !user.pwd.blank?) || user.isregistered?
          Mailer.deliver_account_information(user, user.pwd)
          tmail = Mailer.deliver_fee(user, 'thanks', Setting.template_fee_thanks)
        end
      end
    else
      send_notice("La conferma è gia avvenuta. Se non riccordi le tue credentiali usi la gestione reccupero password.")
    end
    #redirect_to :action => 'login'
    redirect_to editorial_url
  end

  private

  def logout_user
    if User.current.logged?
      cookies.delete :autologin
      Token.delete_all(["user_id = ? AND action = ?", User.current.id, 'autologin'])
      self.logged_user = nil
    end
  end

  def authenticate_user
    if Setting.openid? && using_open_id?
      open_id_authenticate(params[:openid_url])
    else
      password_authentication
    end
  end

  def password_authentication
    user = User.try_to_login(params[:username], params[:password])

    if user.nil?
      invalid_credentials
    elsif user.new_record?
      onthefly_creation_failed(user, {:login => user.login, :auth_source_id => user.auth_source_id})
    else
      # Valid user
      successful_authentication(user)
    end
  end

  def open_id_authenticate(openid_url)
    authenticate_with_open_id(openid_url, :required => [:nickname, :fullname, :email], :return_to => signin_url) do |result, identity_url, registration|
      if result.successful?
        user = User.find_or_initialize_by_identity_url(identity_url)
        if user.new_record?
          # Self-registration off
          #domthu redirect_to(home_url) && return unless Setting.self_registration?
          redirect_to(editorial_url) && return unless Setting.self_registration?

          # Create on the fly
          user.login = registration['nickname'] unless registration['nickname'].nil?
          user.mail = registration['email'] unless registration['email'].nil?
          user.firstname, user.lastname = registration['fullname'].split(' ') unless registration['fullname'].nil?
          user.random_password
          user.register

          case Setting.self_registration
            when '1'
              register_by_email_activation(user) do
                onthefly_creation_failed(user)
              end
            when '3'
              register_automatically(user) do
                onthefly_creation_failed(user)
              end
            else
              register_manually_by_administrator(user) do
                onthefly_creation_failed(user)
              end
          end
        else
          # Existing record
          if user.active?
            successful_authentication(user)
          else
            account_pending
          end
        end
      end
    end
  end

  def successful_authentication(user)
    # Valid user
    self.logged_user = user
    # generate a key and set cookie if autologin
    if params[:autologin] && Setting.autologin?
      set_autologin_cookie(user)
    end
    call_hook(:controller_account_success_authentication_after, {:user => user})
    #domthu redirect on FrontEnd if no permissions for backend
    #if User.current.allowed_to?(:access_back_end, nil, :global => true)
    #if self.logged_user.allowed_to?(:access_back_end, nil, :global => true)
    if user.allowed_to?(:access_back_end, nil, :global => true)
      #Rails.logger.info("login ok collaboratore  #{home_url}  <-Home  editorial-> #{editorial_url}")
      #redirect_to(home_url)
      #redirect_back_or_default :controller => 'my', :action => 'page'
      redirect_to(editorial_url)
      #redirect_back_or_default :controller => 'editorial', :action => 'home'
    else
      if (Setting.fee?)
        user.control_state
        if user.isregistered?
           flash[:notice] = "Periodo di prova valido ancora per " + distance_of_date_in_words(user.scadenza, Time.now)
        end
        if user.isrenewing?
           send_notice("Scadenza abbonamento prossima: " + distance_of_date_in_words(Time.now, self.scadenza))
           send_notice("Rinnovare l'abbonamento.")
        end
      end
      #Rails.logger.info("login ok membro")
      redirect_to(editorial_url)
    end
  end

  def set_autologin_cookie(user)
    token = Token.create(:user => user, :action => 'autologin')
    cookie_name = Redmine::Configuration['autologin_cookie_name'] || 'autologin'
    cookie_options = {
        :value => token.value,
        :expires => 1.year.from_now,
        :path => (Redmine::Configuration['autologin_cookie_path'] || '/'),
        :secure => (Redmine::Configuration['autologin_cookie_secure'] ? true : false),
        :httponly => true
    }
    cookies[cookie_name] = cookie_options
  end

  # Onthefly creation failed, display the registration form to fill/fix attributes
  def onthefly_creation_failed(user, auth_source_options = {})
    @user = user
    session[:auth_source_registration] = auth_source_options unless auth_source_options.empty?
    render :action => 'register'
  end

  def invalid_credentials
    logger.warn "Failed login for '#{params[:username]}' from #{request.remote_ip} at #{Time.now.utc}"
    send_error(l(:notice_account_invalid_creditentials)) #ApplicationController
  end

  # Register a user for email activation.
  #
  # Pass a block for behavior when a user fails to save
  def register_by_email_activation(user, &block)
    token = Token.new(:user => user, :action => "register")
    if user.save and token.save
      Mailer.deliver_register(token)
      flash[:notice] = l(:notice_account_register_done)
      #redirect_to :action => 'login'
      redirect_to editorial_url
    else
      yield if block_given?
    end
  end

  # Automatically register a user
  #
  # Pass a block for behavior when a user fails to save
  def register_automatically(user, &block)
    # Automatic activation
    user.activate
    user.last_login_on = Time.now
    if user.save
      self.logged_user = user
      flash[:notice] = l(:notice_account_activated)
      #redirect_to :controller => 'my', :action => 'account'
      redirect_to editorial_url
    else
      yield if block_given?
    end
  end

  # Manual activation by the administrator
  #
  # Pass a block for behavior when a user fails to save
  def register_manually_by_administrator(user, &block)
    if user.save
      # Sends an email to the administrators
      Mailer.deliver_account_activation_request(user)
      account_pending
    else
      yield if block_given?
    end
  end

  def account_pending
    flash[:notice] = l(:notice_account_pending)
    #redirect_to :action => 'login'
    redirect_to editorial_url
  end

  def reroute_if_logged
    if User.current.logged?
      #redirect_to :controller => 'mio_profilo', :action => 'index'
      redirect_to my_profile_show_url
    end
  end
end

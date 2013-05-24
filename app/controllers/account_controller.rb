# Redmine - project management software
# Copyright (C) 2006-2011  Jean-Philippe Lang
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
  include FeesHelper  #ROLE_XXX  gedate
  before_filter :reroute_if_logged , :only  => :register

  # prevents login action to be filtered by check_if_login_required application scope filter
  skip_before_filter :check_if_login_required

  # Login request and validation
  def login
    #Rails.logger.info("login PARAMS: #{params.inspect}")
    #flash[:notice] = "==========login============="
    #flash[:error] = "==========??????????============="
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
          redirect_to :action => 'login'
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
          redirect_to :action => 'login'
          return
        end
      end
    end
  end

  # User self-registration
  def register
    #puts "********************REGISTER********************"
    #domthu redirect_to(home_url) && return unless Setting.self_registration? || session[:auth_source_registration]
    redirect_to(editorial_url) && return unless Setting.self_registration? || session[:auth_source_registration]
    if request.get?
      session[:auth_source_registration] = nil
      @user = User.new(:language => Setting.default_language)
    else
      @user = User.new(params[:user])
      @user.admin = false
      #default role_id
      @user.role_id = FeeConst::ROLE_REGISTERED
      #di default non viene abilitato

      #Collect fs custom data
#Parameters: {"user_asso_id"=>"41", "extra_organismo"=>"", "user_telefono"=>"123123123", "user_se_condition"=>"1", "extra"=>{"cross_id"=>"", "asso_id"=>""}, "commit"=>"Invia", "user_cross_organization_id"=>"1", "user_Town"=>"castelr", "action"=>"register", "password"=>"[FILTERED]", "user_fax"=>"213124123412", "user"=>{"codice"=>"123123123", "login"=>"domthu2", "soc"=>"", "mail"=>"dom.thual@gmail.com", "lastname"=>"thual", "num_reg_coni"=>"123123", "comune_id"=>"", "firstname"=>"dominique", "language"=>"it"}, "authenticity_token"=>"KjT8SLqtKJm23yzGzhC00MMQqSsq/JuZJTXYovMMz80=", "user_titolo"=>"Altro", "user_note"=>"qualcosa", "controller"=>"account", "user_indirizzo"=>"via monte vettore", "password_confirmation"=>"[FILTERED]", "user_se_privacy"=>"1"}
      #user firstname
      #user lastname
      #user mail
      #user login
      #user password
      #user password_confirmation
      #user language
      #user se_condition =>"1"
      #user se_privacy =>"1"
      #user titolo
      #user reg_coni
      #extra cross_id
      #extra asso_id
      #extra organismo
      #user soc
      #user comune_id
      #user indirizzo
      #user telefono
      #user fax
      #user codice
      #user note

      if !params[:user][:se_condition].nil? && params[:user][:se_condition] && !params[:user][:se_condition].blank?
        @user.se_condition = params[:user][:se_condition]
      else
        flash.now[:error] = l(:notice_register_must_condition);
        return
      end
      if !params[:user][:se_privacy].nil? && params[:user][:se_privacy] && !params[:user][:se_privacy].blank?
        @user.se_privacy = params[:user][:se_privacy]
      else
        flash.now[:error] = l(:notice_register_must_consensus);
        return
      end

      #Region Province Comune
      if !params[:user][:comune_id].nil? && params[:user][:comune_id] && !params[:user][:comune_id].blank?
        #puts "CCCCCCCCCCCCCCCCC #{params[:user][:comune_id]} CCCCCCCCCCC"
        @user.comune_id = params[:user][:comune_id].to_i
        #INUTILE basta usare comune_id
        #retreive CAP, Città, ProvinceID
        @Citta = Comune.find(params[:user][:comune_id])
        if @Citta #province_id region_id	cap
          @user.cap = @Citta.cap
          @user.prov = @Citta.province.name + "(" + @Citta.province_id.to_s + ")"
        end
      end
      #STEP3 CONI FSN e Associazione
      if ((params[:extra][:asso_id]) && (params[:extra][:cross_id]))
        @user.asso_id = params[:extra][:asso_id].to_i
        @user.cross_organization_id = params[:extra][:cross_id].to_i
        #Region Province Comune --> inutile le abbiamo dentro la
      else
        if (params[:user][:asso_id])
          #puts "AAAAAAAAAAAAAAAA #{params[:user][:asso_id]} AAAAAAAAAAA"
          #@user.tiposigla_id = params[:user][:tiposigla_id]
          #@user.organismo_id = params[:user][:organismo_id]
          @user.asso_id = params[:user][:asso_id].to_i
        end
        if (params[:user][:organization_id])
          @user.cross_organization_id = params[:user][:organization_id].to_i
        end
      end
      if (params[:user][:mail])
        @user.mail_fisco = params[:user][:mail]
      end

      @user.register
      if session[:auth_source_registration]
        @user.activate
        @user.login = session[:auth_source_registration][:login]
        @user.auth_source_id = session[:auth_source_registration][:auth_source_id]
        if @user.save
          session[:auth_source_registration] = nil
          self.logged_user = @user
          flash[:notice] = l(:notice_account_activated)
          redirect_to :controller => 'my', :action => 'account'
        end
      else
        @user.login = params[:user][:login]
        @user.password, @user.password_confirmation = params[:password], params[:password_confirmation]

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
    @user.random_password  #    self.password = password & self.password_confirmation = password
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
        @errors += "<br />Errore completa: " + @user.errors.full_messages.join('<br />')
      end
      puts "********************Prova user not valid (" + @errors + ")********************"
      #format.html { return redirect_to :controller => 'editorial', :action => 'prova', :user => @user }
      #format.js {
      return render :json => {
          :success => false,
          :response => @stat,
          :errors => @errors
        }
      #}
    end

    raise_delivery_errors = ActionMailer::Base.raise_delivery_errors
    # Force ActionMailer to raise delivery errors so we can catch it
    ActionMailer::Base.raise_delivery_errors = true
    @stat = 'Invio email non riuscito '
    begin
      if @user.save
        puts "++++++++++++++++++Prova saved (" + @errors + ")++++++++++++++++"
        @user.register #update_attribute
        @stat = " Utente registrato"
        self.logged_user = @user
        # Sends an email to the administrators
        Mailer.deliver_account_activation_request(@user)
      else
        if !@user.errors.empty?
          #@errors += @user.errors.join(', ') undefined method join
          @errors += "<br />errore completa: " + @user.errors.full_messages.join('<br />')
        end
        puts "********************Prova user not saved! (" + @errors + ")********************"
        @stat += "Tipo registrazione(" + Setting.self_registration + "). "
        case Setting.self_registration
        when '1'
          @stat += " Utente registrato, in attesa della conferma email"
          #register_by_email_activation(@user)
          token = Token.new(:user => @user, :action => "register")
          if @user.save and token.save
            @user.register #verificare se farlo? update_attribute
            Mailer.deliver_register(token)
            @stat += l(:notice_account_register_done)
          else
            puts "********************Prova self_registration 1 KAPPAO (" + @errors + ")********************"
            @stat += " Conferma email: <span style='color: red; font-weight: bolder;'>Utente NON registrato e quindi nessuna email di conferma inviata</span>"
          end

        when '3' # Automatic activation
          @stat += " Utente registrato automaticamente"
          #register_automatically(@user)
          @user.activate
          @user.last_login_on = Time.now
          if @user.save
            @user.register #verificare se farlo? update_attribute
            self.logged_user = @user
            @stat += l(:notice_account_activated)
          else
            puts "********************Prova self_registration 3 KAPPAO (" + @errors + ")********************"
            @stat += " Creazione automatica: <span style='color: red; font-weight: bolder;'> Utente NON registrato automaticamente</span>"
          end

        else
          @stat += " Utente NON registrato: richiede registrazione manuale da parte dell'amministratore"
          #register_manually_by_administrator(@user)
          if @user.save
            @user.register #verificare se farlo? update_attribute
            # Sends an email to the administrators
            Mailer.deliver_account_activation_request(user)
            account_pending
          else
            puts "********************Prova self_registration other KAPPAO (" + @errors + ")********************"
            @stat += " Creazione manuale da Admin: <span style='color: red; font-weight: bolder;'>Utente NON registrato e quindi l'amministratore deve fare una registrazione manuale</span>"
          end

        end
      end
      #htmlpartial = render_to_string(
      #  :layout => false,
      #  :partial => 'user/show',
      #  :locals => { :user => @user }
      #)
      #htmlpartial = 'pippo'
      #htmlpartial = getuserhtml(@user)
      htmlpartial = ''
      @tmail = Mailer.deliver_prova_gratis(@user, @stat + "<br />" + htmlpartial)
      @stat += "Email inviato correttamente: <br /><strong>Verifichi la tua cassela postale e confermi la tua email</strong>"
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
        :locals => { :user => user }
      )
      #  :partial => 'user/show',
  end

  # Token based account activation
  def activate
    #domthu redirect_to(home_url) && return unless Setting.self_registration? && params[:token]
    redirect_to(editorial_url) && return unless Setting.self_registration? && params[:token]
    token = Token.find_by_action_and_value('register', params[:token])
    #domthu redirect_to(home_url) && return unless Setting.self_registration? && params[:token]
    redirect_to(editorial_url) && return unless Setting.self_registration? && params[:token]
    user = token.user
    #domthu redirect_to(home_url) && return unless user.registered?
    redirect_to(editorial_url) && return unless user.registered?
    user.activate
    if user.save
      token.destroy
      flash[:notice] = l(:notice_account_activated)
    end
    redirect_to :action => 'login'
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
      onthefly_creation_failed(user, {:login => user.login, :auth_source_id => user.auth_source_id })
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
    call_hook(:controller_account_success_authentication_after, {:user => user })
    #domthu redirect on FrontEnd if no permissions for backend
    #if User.current.allowed_to?(:access_back_end, nil, :global => true)
    #if self.logged_user.allowed_to?(:access_back_end, nil, :global => true)
    if user.allowed_to?(:access_back_end, nil, :global => true)
      Rails.logger.info("login ok collaboratore  #{home_url}  <-Home  editorial-> #{editorial_url}")
      #redirect_to(home_url)
      #redirect_back_or_default :controller => 'my', :action => 'page'
      redirect_to(editorial_url)
      #redirect_back_or_default :controller => 'editorial', :action => 'home'
    else
      if (Setting.fee?)
        #TODO Controllare la scadenza se è di RUOLO

       # str = control_assign_role(user)
       # Rails.logger.info("Login controllo ruolo: " + str)
      end
      Rails.logger.info("login ok membro")
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
  def onthefly_creation_failed(user, auth_source_options = { })
    @user = user
    session[:auth_source_registration] = auth_source_options unless auth_source_options.empty?
    render :action => 'register'
  end

  def invalid_credentials
    logger.warn "Failed login for '#{params[:username]}' from #{request.remote_ip} at #{Time.now.utc}"
    flash.now[:error] = l(:notice_account_invalid_creditentials)
  end

  # Register a user for email activation.
  #
  # Pass a block for behavior when a user fails to save
  def register_by_email_activation(user, &block)
    token = Token.new(:user => user, :action => "register")
    if user.save and token.save
      Mailer.deliver_register(token)
      flash[:notice] = l(:notice_account_register_done)
      redirect_to :action => 'login'
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
      redirect_to :controller => 'my', :action => 'account'
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
    redirect_to :action => 'login'
  end
  def reroute_if_logged
    if User.current.logged?
      redirect_to :controller => 'mio_profilo', :action => 'index'
    end
  end
end

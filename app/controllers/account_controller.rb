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

#Parameters: {"action"=>"register", "authenticity_token"=>"P7eqAhfI5yeK+jAXK3NFvXLbBYyPT058LyJtDJva+Ks=", "commit"=>"Invia", "user"=>{"codicefiscale"=>"", "mail"=>"domthu@ks3000495.kimsufi.com", "sez"=>"", "language"=>"it", "se_condition"=>"1", "comune_id"=>"4035", "partitaiva"=>"", "soc"=>"", "indirizzo"=>"", "login"=>"dom1", "lastname"=>"thual1", "firstname"=>"dom1", "cross_organization_id"=>"", "titolo"=>"Responsabile", "password"=>"[FILTERED]", "se_privacy"=>"1", "fax"=>"", "telefono"=>"", "password_confirmation"=>"[FILTERED]"}, "controller"=>"account", "extra_town"=>"4035"}
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

      #Region Province Comune
      if params[:user][:comune_id].present?
        @user.comune_id = params[:user][:comune_id].to_i
        @Citta = Comune.find(params[:user][:comune_id])
        if @Citta #province_id region_id	cap
          @user.cap = @Citta.cap
          @user.prov = @Citta.province.name + "(" + @Citta.province_id.to_s + ")"
        end
      end

      #STEP3 CONI FSN e convenzione
      #if params[:extra] && params[:extra][:convention_select]) && params[:extra][:cross_select]
      #  @user.convention_id = params[:extra][:convention_select].to_i
      #  @user.cross_organization_id = params[:extra][:cross_select].to_i
      #  #Region Province Comune --> inutile le abbiamo dentro la
      #else
        #if (params[:user][:convention_id])
        #  @user.convention_id = params[:user][:convention_id].to_i
        #end
      if (params[:user][:cross_organization_id])
        @user.cross_organization_id = params[:user][:cross_organization_id].to_i
      end
      #end
      if (params[:user][:mail])
        @user.mail_fisco = params[:user][:mail]
      end

      @user.register
      if session[:auth_source_registration]
        @user.activate
        @user.login = session[:auth_source_registration][:login]
        @user.auth_source_id = session[:auth_source_registration][:auth_source_id]
        #impostazioni minimali di default
        @user.datascadenza = Date.today + Setting.register_days.to_i
        @user.role_id = FeeConst::ROLE_REGISTERED
        # se dichiara di essere convenzionato
        if @user.save
          session[:auth_source_registration] = nil
          self.logged_user = @user
          flash[:notice] = l(:notice_account_activated)
          #redirect_to :controller => 'my', :action => 'account'
          redirect_to my_profile_show_url
        end
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
      @stat += "Email inviata correttamente: <br /><strong>Verifichi la sua casella postale e confermi la sua email</strong>"
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
           flash[:notice] = "Scadenza abbonamento prossima: " + distance_of_date_in_words(Time.now, self.scadenza) + "<br />Rinnovare l'abbonamento."
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
    if flash[:error].nil?
      flash.now[:error] = l(:notice_account_invalid_creditentials)
    else
      flash[:error] += '<br />' + l(:notice_account_invalid_creditentials)
    end
  end

  # Register a user for email activation.
  #
  # Pass a block for behavior when a user fails to save
  def register_by_email_activation(user, &block)
    token = Token.new(:user => user, :action => "register")
    if user.save and token.save
      Mailer.deliver_register(token)
      if user.isregistered?
        Mailer.deliver_account_information(user, user.password)
        Mailer.fee(self, 'thanks', Setting.template_fee_thanks)
      end
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

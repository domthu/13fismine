class FeesController < ApplicationController

  layout 'admin'

  before_filter :require_admin, :require_fee
  #before_filter :find_user, :only => [:registrati, :associati, :privati, :archiviati, :scaduti]
  before_filter :get_statistics, :only => [:index, :registrati, :associati, :privati, :archiviati, :scaduti]

  helper :sort
  include SortHelper

  #include UsersHelper #def change_status_link(user)   #Kappao cyclic include detected
  include FeesHelper  #ROLE_XXX  gedate
  #ROLE_MANAGER        = 3  #Manager<br />
  #ROLE_AUTHOR         = 4  #Redattore  <br />
  ##ROLE_COLLABORATOR   = 4  #ROLE_REDATTORE   autore, redattore e collaboratore
  #ROLE_VIP            = 10 #Invitato Gratuito<br />
  #ROLE_ABBONATO       = 6  #Abbonato user.data_scade
  #ROLE_REGISTERED     = 9  #Ospite periodo di prova durante
  #ROLE_RENEW          = 11  #Rinnovo: periodo prima della scadenza
  #ROLE_EXPIRED        = 7  #Scaduto: user.data_scadenza < today<br />
  #ROLE_ARCHIVIED      = 8  #Archiviato: bloccato: puo uscire da questo stato solo
  include ActionView::Helpers::DateHelper
  #undefined method `utc?' for Wed, 15 Oct 2008:Date  format_time --> format_date

  def index
    #@msg[] << ""
    if params['verify'].to_i == 1
      @msg = ["---Verificazione degli utenti---"]
      #User.each do |user|
      #    existing_regions = Region.all()
      #for usr in User.all(:limit => 20) do
      for usr in User.all() do
        str = control_assign_role(usr)
        if !str.nil?
          @msg << str
        end
      end
    end

    #Ruoli non sottoposti a controllo di abbonamento
    #ROLE_MANAGER        = 3  #Manager<br />
    #BY INTERNAL ROLE
    #ROLE_AUTHOR         = 4 = ROLE_COLLABORATOR
    #  ROLE_VIP            = 9
    @num_no_role = User.all(:conditions => {:role_id => nil}).count
    @num_admin = User.all(:conditions => {:admin => 1}).count
    @name_admin = User.all(:conditions => {:admin => 1})
    @num_power_user = User.all(:conditions => {:power_user => 1}).count
    @name_power_user = User.all(:conditions => {:power_user => 1})
    @num_manager = User.all(:conditions => {:role_id => ROLE_MANAGER}).count
    @name_manager = User.all(:conditions => {:role_id => ROLE_MANAGER})

    @num_author = User.all(:conditions => {:role_id => ROLE_AUTHOR}).count
    @name_author = User.all(:conditions => {:role_id => ROLE_AUTHOR})
    #@num_collaboratori = User.all(:conditions => {:role_id => ROLE_COLLABORATOR}).count
    #@name_collaboratori = User.all(:conditions => {:role_id => ROLE_COLLABORATOR})
    @num_invitati = User.all(:conditions => {:role_id => ROLE_VIP}).count
    @name_invitati = User.all(:conditions => {:role_id => ROLE_VIP})
    #BY CLIENT ROLE
    #  ROLE_ABBONATO       = 5  #user.data_scadenza > (today - Setting.renew_days)
    #  ROLE_RENEW          = 8  #periodo prima della scadenza dipende da Setting.renew_days
    #  ROLE_REGISTERED     = 7  #periodo di prova durante Setting.register_days
    #  ROLE_EXPIRED        = 6  #user.data_scadenza < today
    #  ROLE_ARCHIVIED      = 4  #bloccato: puo uscire da questo stato solo manualmente ("Ha pagato", "invito di prova"=REGISTERED)
    @num_abbonati = User.all(:conditions => {:role_id => ROLE_ABBONATO}).count
    @num_rinnovamento = User.all(:conditions => {:role_id => ROLE_RENEW}).count
    @num_registrati = User.all(:conditions => {:role_id => ROLE_REGISTERED}).count
    @num_scaduti = User.all(:conditions => {:role_id => ROLE_EXPIRED}).count
    @num_archiviati = User.all(:conditions => {:role_id => ROLE_ARCHIVIED}).count

    #Who pay?
    #BY PAYMENTS PRIVATE or CROSS ORGANIZATION
    #@num_power_user = User.all(:conditions => {:power_user => 1}).count
    #User member of ASSOCIATION
    @num_Associations =  Asso.all.count
    @num_Associated =  User.all(:conditions => {:asso_id => !nil}).count
    @num_power_user = User.all(:conditions => {:power_user => true}).count
    #Utenti che non dipendono di un associazione PAGANTI
    @num_maybe_privati = User.all(:conditions => {:asso_id => nil}).count
    #@num_privati = User.all(:conditions => {:asso_id => nil, :role_id => nil}).count
    @roles = []
    @roles << ROLE_ABBONATO << ROLE_RENEW << ROLE_REGISTERED << ROLE_EXPIRED << ROLE_ARCHIVIED
    @num_privati = User.all(:conditions => ['asso_id is null AND role_id IN (?)', @roles]).count
    @active = []
    @active << ROLE_ABBONATO << ROLE_RENEW << ROLE_REGISTERED
    @num_active = User.all(:conditions => ['asso_id is null AND role_id IN (?)', @active]).count

    #AFFILIATI
    @num_organismi = CrossOrganization.all.count
    @num_members =  User.all(:conditions => {:cross_organization_id => !nil}).count


  end


###########LISTE UTENTI PER RUOLO##############
  def paganti
    #  ROLE_ABBONATO       = 5  #user.data_scadenza > (today - Setting.renew_days)
    #  ROLE_RENEW          = 8  #periodo prima della scadenza dipende da Setting.renew_days
    @users = User.find(
    :all,
    :conditions => ["role_id = :role_1 OR role_id = :role_2 ", { :role_1 => ROLE_ABBONATO, :role_2 => ROLE_RENEW } ],
    :include => :role)
    #:conditions => {:role_id => ROLE_ABBONATO, :role_id => ROLE_RENEW },

#    workflows.find(:all,
#        :include => :new_status,
#        :conditions => ["role_id IN (:role_ids) AND tracker_id = :tracker_id AND (#{conditions})",
#          {:role_ids => roles.collect(&:id), :tracker_id => tracker.id, :true => true, :false => false}
#          ]
#        ).collect{|w| w.new_status}.compact.sort

  end

  def registrati
    #  ROLE_REGISTERED     = 7  #periodo di prova durante Setting.register_days
    #@users = User.all(:conditions => {:role_id => ROLE_REGISTERED}, :include => :role)
    sort_init 'person', 'asc'
    sort_update %w(firstname lastname role_id created_on asso_id datascadenza)

    case params[:format]
    when 'xml', 'json'
      @offset, @limit = api_offset_and_limit
    else
      @limit = per_page_option
    end

    scope = User
    scope = scope.in_role(params[:role_id].to_i) if params[:role_id].present?
    @roleid = params[:role_id].to_i if params[:role_id].present?

    @status = params[:status] ? params[:status].to_i : 1
    c = ARCondition.new(@status == 0 ? "status <> 0" : ["status = ?", @status])

    unless params[:name].blank?
      name = "%#{params[:name].strip.downcase}%"
      c << ["LOWER(login) LIKE ? OR LOWER(firstname) LIKE ? OR LOWER(lastname) LIKE ? OR LOWER(mail) LIKE ?", name, name, name, name]
    end

    @user_count = scope.count(:conditions => c.conditions)
    @user_pages = Paginator.new self, @user_count, @limit, params['page']
    @offset ||= @user_pages.current.offset
    @users =  scope.find :all,
                        :order => sort_clause,
                        :conditions => c.conditions,
                        :limit  =>  @limit,
                        :offset =>  @offset

    respond_to do |format|
      format.html {
        render :layout => !request.xhr?
      }
      format.api
    end
  end

  def scaduti
    #  ROLE_EXPIRED        = 6  #user.data_scadenza < today
    @users = User.all(:conditions => {:role_id => ROLE_EXPIRED}, :include => :role)
  end

  def archiviati
    #  ROLE_ARCHIVIED      = 4  #bloccato: puo uscire da questo stato solo manualmente ("Ha pagato", "invito di prova"=REGOISTERED)
    @users = User.all(:conditions => {:role_id => ROLE_ARCHIVIED}, :include => :role)
  end


  def abbonamenti
    @username = params[:user] ? params[:user].to_i : ''
    @users = User.find_by_api_key(@username)
    @role = params[:role] ? params[:role].to_i : 1
    @users_role = User.all(:conditions => {:role_id => @role}, :include => :role)
#    :conditions => "parent_id IS NULL AND status = #{Project::STATUS_ACTIVE}",
  end

  def privati
  end

  def associati
  end

##########GESTIONE PAGAMENTI ABBONAMENTO
  def pagamento
  end

  def invia_fatture
  end

  #Mailer.Deliver_fee
  #in models/def fee(user, type, setting_text)
  #add route /fees/email_fee
  def email_fee
    #proposal
    #thanks
    #asso
    #renew
    @type = params[:type]
    raise_delivery_errors = ActionMailer::Base.raise_delivery_errors
    # Force ActionMailer to raise delivery errors so we can catch it
    ActionMailer::Base.raise_delivery_errors = true
    begin
      #lib/tasks/email.rake
      #app/models/mailer.rb  -> def fee(user, type, setting_text)   fee e fee_url
      #app/invoice/views/_fee.text.erb
      #app/invoice/views/_fee.html.erb
      if @type == 'proposal'
        @test = Mailer.deliver_fee(User.current, @type, Setting.template_fee_proposal)
      elsif @type == 'thanks'
        @test = Mailer.deliver_fee(User.current, @type, Setting.template_fee_thanks)
      elsif @type == 'asso'
        @test = Mailer.deliver_fee(User.current, @type, Setting.template_fee_register_asso)
      elsif @type == 'renew'
        @test = Mailer.deliver_fee(User.current, @type, Setting.template_fee_renew)
      end
      flash[:notice] = l(:notice_email_sent, User.current.mail)
    rescue Exception => e
      flash[:error] = l(:notice_email_error, e.message)
    end
    ActionMailer::Base.raise_delivery_errors = raise_delivery_errors
    redirect_to :controller => 'settings', :action => 'edit', :tab => 'fee'
  end

  verify :method => :put, :only => :update, :render => {:nothing => true, :status => :method_not_allowed }
  def update_role
    @user.admin = params[:user][:admin] if params[:user][:admin]
    @user.login = params[:user][:login] if params[:user][:login]
    if params[:user][:password].present? && (@user.auth_source_id.nil? || params[:user][:auth_source_id].blank?)
      @user.password, @user.password_confirmation = params[:user][:password], params[:user][:password_confirmation]
    end
    @user.safe_attributes = params[:user]
    # Was the account actived ? (do it before User#save clears the change)
    was_activated = (@user.status_change == [User::STATUS_REGISTERED, User::STATUS_ACTIVE])
    # old role
    was_role_id = User.find(@user).role_id

    if @user.save

      if was_activated
        Mailer.deliver_account_activated(@user)
      elsif @user.active? && params[:send_information] && !params[:user][:password].blank? && @user.auth_source_id.nil?
        Mailer.deliver_account_information(@user, params[:user][:password])
      end

      respond_to do |format|
        format.html {
          flash[:notice] = l(:notice_successful_update)
          redirect_to :back
        }
        format.api  { head :ok }
      end
    else
      @auth_sources = AuthSource.find(:all)
      @membership ||= Member.new
      # Clear password input
      @user.password = @user.password_confirmation = nil

      respond_to do |format|
        format.html { render :action => :edit }
        format.api  { render_validation_errors(@user) }
      end
    end
  rescue ::ActionController::RedirectBackError
    redirect_to :controller => 'users', :action => 'edit', :id => @user
  end


################################
  private

    def get_statistics
      @num_users = User.count
      #@num_users = User.all.count
    end

    def require_fee
      if !Setting.fee
        flash[:notice] = l(:notice_setting_fee_not_allowed)
        redirect_to editorial_path
      end
    end

    def find_user
      if params[:id] == 'current'
        require_login || return
        @user = User.current
      else
        @user = User.find(params[:id])
      end
    rescue ActiveRecord::RecordNotFound
      render_404
    end

end

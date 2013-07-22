class FeesController < ApplicationController

  layout 'admin'

  before_filter :require_admin, :require_fee
  #before_filter :find_user, :only => [:registrati, :associati, :privati, :archiviati, :scaduti]
  before_filter :get_statistics, :only => [:index, :registrati, :associati, :privati, :archiviati, :scaduti]

  helper :sort
  include SortHelper

  #include UsersHelper #def change_status_link(user)   #Kappao cyclic include detected
  include FeesHelper  #ROLE_XXX  gedate
  #FeeConst::ROLE_MANAGER        = 3  #Manager<br />
  #FeeConst::ROLE_AUTHOR         = 4  #Redattore  <br />
  #FeeConst::ROLE_COLLABORATOR   = 4  #ROLE_REDATTORE   autore, redattore e collaboratore
  #FeeConst::ROLE_VIP            = 10 #Invitato Gratuito<br />
  #FeeConst::ROLE_ABBONATO       = 6  #Abbonato user.data_scade
  #FeeConst::ROLE_REGISTERED     = 9  #Ospite periodo di prova durante
  #FeeConst::ROLE_RENEW          = 11  #Rinnovo: periodo prima della scadenza
  #FeeConst::ROLE_EXPIRED        = 7  #Scaduto: user.data_scadenza < today<br />
  #FeeConst::ROLE_ARCHIVIED      = 8  #Archiviato: bloccato: puo uscire da questo stato solo
  include ActionView::Helpers::DateHelper
  #undefined method `utc?' for Wed, 15 Oct 2008:Date  format_time --> format_date

  def index
    #@msg[] << ""
    #__User_all = User.all()

    if params['verify'].to_i == 1
      @msg = ["---Verifica degli utenti---"]
      #_ArrStr = Array.new
      #_ArrStr.push "---Init---"
      #User.each do |user|
      #    existing_regions = Region.all()
      #for usr in User.all(:limit => 5) do
      for usr in User.all() do
        #puts "user --> " + usr.id.to_s
        str = control_assign_role(usr)
        if !str.nil?
          @msg << str
        end
      end
    end

    @num_no_role = User.all(:conditions => {:role_id => nil || 2}).count

    #Ruoli non sottoposti a controllo di abbonamento
    #FeeConst::ROLE_MANAGER        = 3  #Manager<br />
    #BY INTERNAL ROLE
    #FeeConst::ROLE_AUTHOR         = 4 = ROLE_COLLABORATOR
    #  FeeConst::ROLE_VIP            = 9
    @name_admin = User.all(:conditions => {:admin => 1})
    @name_admin_count = @name_admin.count
    #name_power_user = User.all(:conditions => {:power_user => 1})
    @name_manager = User.all(:conditions => {:role_id => FeeConst::ROLE_MANAGER})
    @name_manager_count = @name_manager.count
    @name_author = User.all(:conditions => {:role_id => FeeConst::ROLE_AUTHOR})
    @name_author_count = @name_author.count
    #@name_collaboratori = User.all(:conditions => {:role_id => ROLE_COLLABORATOR})
    @name_invitati = User.all(:conditions => {:role_id => FeeConst::ROLE_VIP})
    @name_invitati_count = @name_invitati.count
    @num_uncontrolled_TOTAL = @name_manager_count + @name_author_count + @name_invitati_count


    #BY CLIENT ROLE
    #  FeeConst::ROLE_ABBONATO       = 5  #user.data_scadenza > (today - Setting.renew_days)
    #  FeeConst::ROLE_RENEW          = 8  #periodo prima della scadenza dipende da Setting.renew_days
    #  FeeConst::ROLE_REGISTERED     = 7  #periodo di prova durante Setting.register_days
    #  FeeConst::ROLE_EXPIRED        = 6  #user.data_scadenza < today
    #  FeeConst::ROLE_ARCHIVIED      = 4  #bloccato: puo uscire da questo stato solo manualmente ("Ha pagato", "invito di prova"=REGISTERED)
    @num_abbonati = User.all(:conditions => {:role_id => FeeConst::ROLE_ABBONATO}).count
    @num_rinnovamento = User.all(:conditions => {:role_id => FeeConst::ROLE_RENEW}).count
    @num_registrati = User.all(:conditions => {:role_id => FeeConst::ROLE_REGISTERED}).count
    @num_scaduti = User.all(:conditions => {:role_id => FeeConst::ROLE_EXPIRED}).count
    @num_archiviati = User.all(:conditions => {:role_id => FeeConst::ROLE_ARCHIVIED}).count
    @num_controlled_TOTAL = @num_abbonati + @num_rinnovamento + @num_registrati + @num_scaduti + @num_archiviati

    #Who pay?
    #BY PAYMENTS PRIVATE or CONVENTION
    #@num_power_user = User.all(:conditions => {:power_user => 1}).count
    #User member of organismo convenzionato
    @num_Associations =  Convention.all.count
    @referee = User.find_by_sql("select * from users where id IN (select distinct user_id from conventions)")
    #questi utenti non pagano. Paga l'organismo convenzionato
    @num_Associated_COUNT =  User.all(:conditions => 'convention_id IS NOT NULL').count
    @num_Associated_ABBONATO =  User.all(:conditions => ['convention_id IS NOT NULL AND role_id = ?',  FeeConst::ROLE_ABBONATO]).count
    @num_Associated_REGISTERED =  User.all(:conditions => ['convention_id IS NOT NULL AND role_id = ?',  FeeConst::ROLE_REGISTERED]).count
    @num_Associated_RENEW =  User.all(:conditions => ['convention_id IS NOT NULL AND role_id = ?',  FeeConst::ROLE_RENEW]).count
    @num_Associated_EXPIRED =  User.all(:conditions => ['convention_id IS NOT NULL AND role_id = ?',  FeeConst::ROLE_EXPIRED]).count
    @num_Associated_ARCHIVIED =  User.all(:conditions => ['convention_id IS NOT NULL AND role_id = ?',  FeeConst::ROLE_ARCHIVIED]).count
    @num_associated_TOTAL = @num_Associated_ABBONATO + @num_Associated_REGISTERED + @num_Associated_RENEW + @num_Associated_EXPIRED + @num_Associated_ARCHIVIED

    #Utenti che non dipendono di un associazione PAGANTI
    #@num_privati_COUNT = User.all(:conditions => {:convention_id => nil}).count
    @roles = []
    @roles << FeeConst::ROLE_MANAGER << FeeConst::ROLE_AUTHOR << FeeConst::ROLE_VIP
    @num_privati_COUNT = User.all(:conditions => ['convention_id is null AND role_id not IN (?)', @roles]).count
    #@num_privati_AUTHOR =  User.all(:conditions => {:convention_id => nil, :role_id =>  FeeConst::ROLE_AUTHOR}).count
    #@num_privati_VIP =  User.all(:conditions => {:convention_id => nil, :role_id =>  FeeConst::ROLE_VIP}).count
    @num_privati_ABBONATO =  User.all(:conditions => {:convention_id => nil, :role_id =>  FeeConst::ROLE_ABBONATO}).count
    @num_privati_REGISTERED =  User.all(:conditions => {:convention_id => nil, :role_id =>  FeeConst::ROLE_REGISTERED}).count
    @num_privati_RENEW =  User.all(:conditions => {:convention_id => nil, :role_id =>  FeeConst::ROLE_RENEW}).count
    @num_privati_EXPIRED =  User.all(:conditions => {:convention_id => nil, :role_id =>  FeeConst::ROLE_EXPIRED}).count
    @num_privati_ARCHIVIED =  User.all(:conditions => {:convention_id => nil, :role_id =>  FeeConst::ROLE_ARCHIVIED}).count
    @num_privati_TOTAL = @num_privati_ABBONATO + @num_privati_REGISTERED + @num_privati_RENEW + @num_privati_EXPIRED + @num_privati_ARCHIVIED
    @num_controlled_TOTAL

    #Affiliati ad una federazione (cross organization)
    #CONI è nazionale
    @num_organismi = CrossOrganization.all.count
    @num_members =  User.all(:conditions => {:cross_organization_id => !nil}).count

  end


###########LISTE UTENTI PER RUOLO##############
  def registrati
    #  FeeConst::ROLE_REGISTERED     = 7  #periodo di prova durante Setting.register_days
    #@users = User.all(:conditions => {:role_id => FeeConst::ROLE_REGISTERED}, :include => :role)
    sort_init 'person', 'asc'
    sort_update %w(firstname lastname role_id created_on convention_id datascadenza)

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
    #  FeeConst::ROLE_EXPIRED        = 6  #user.data_scadenza < today
    @users = User.all(:conditions => {:role_id => FeeConst::ROLE_EXPIRED}, :include => :role)
  end

  def archiviati
    #  FeeConst::ROLE_ARCHIVIED      = 4  #bloccato: puo uscire da questo stato solo manualmente ("Ha pagato", "invito di prova"=REGOISTERED)
    @users = User.all(:conditions => {:role_id => FeeConst::ROLE_ARCHIVIED}, :include => :role)
  end


  def abbonamenti
    @username = params[:username] ? params[:username].to_s : ''
    @users = User.find_by_api_key(@username)
    @role = params[:role] ? params[:role].to_i : 1
    @users_role = User.all(:conditions => {:role_id => @role}, :include => :role)
#    :conditions => "parent_id IS NULL AND status = #{Project::STATUS_ACTIVE}",
  end

  def privati
  end

  def associati
      #sort and filters users
    sort_init 'login', 'asc'
    #sort_update %w(login firstname lastname mail admin created_on last_login_on)
    sort_update %w(lastname mail data convention_id role_id)

    #@limit = per_page_option

    scope = @users_by_roles

    c = ARCondition.new(["users.type = 'User'"])
    c << ["convention_id is not null"]
    if request.post?
      #ricerca testuale
      unless params[:name].blank?
        @name = params[:name]
        name = "%#{params[:name].strip.downcase}%"
        c << ["LOWER(login) LIKE ? OR LOWER(firstname) LIKE ? OR LOWER(lastname) LIKE ? OR LOWER(mail) LIKE ?", name, name, name, name]
      end
      #Convention filter
      @convention_id = (params[:convention] && params[:convention][:convention_id]) ? params[:convention][:convention_id].to_i : 0
      if @convention_id > 0
        c << ["convention_id = ? ", @convention_id.to_s]
      end
    else
      @convention_id = Convention.All(:first).id
      c << ["convention_id = ?", @convention_id]

    end

    @users =  User.find :all,
                :order => sort_clause,
                :conditions => c.conditions
  end

  def paganti
    #  FeeConst::ROLE_ABBONATO       = 5  #user.data_scadenza > (today - Setting.renew_days)
    #  FeeConst::ROLE_RENEW          = 8  #periodo prima della scadenza dipende da Setting.renew_days
    #@users = User.find(
    #:all,
    #:conditions => ["role_id = :role_1 OR role_id = :role_2 ", { :role_1 => FeeConst::ROLE_ABBONATO, :role_2 => FeeConst::ROLE_RENEW } ],
    #:include => :role)
    #:conditions => {:role_id => FeeConst::ROLE_ABBONATO, :role_id => FeeConst::ROLE_RENEW },

#    workflows.find(:al,
#        :include => :new_status,
#        :conditions => ["role_id IN (:role_ids) AND tracker_id = :tracker_id AND (#{conditions})",
#          {:role_ids => roles.collect(&:id), :tracker_id => tracker.id, :true => true, :false => false}
#          ]
#        ).collect{|w| w.new_status}.compact.sort

    #sort and filters users
    sort_init 'login', 'asc'
    #sort_update %w(login firstname lastname mail admin created_on last_login_on)
    sort_update %w(lastname mail data convention_id role_id)

    #@limit = per_page_option

    scope = @users_by_roles

    c = ARCondition.new(["users.type = 'User'"])
    c << ["convention_id is null"]
    if request.post?
      @abbo = params[:abbo] ? params[:abbo].to_i : 0
      if (@abbo > 0)
        c << ["role_id = ?", @abbo]
      #else
      #  c << ["role_id IN (?) ", FeeConst::NEWSLETTER_ROLES]
      end
      #ricerca testuale
      unless params[:name].blank?
        @name = params[:name]
        name = "%#{params[:name].strip.downcase}%"
        c << ["LOWER(login) LIKE ? OR LOWER(firstname) LIKE ? OR LOWER(lastname) LIKE ? OR LOWER(mail) LIKE ?", name, name, name, name]
      end
      #Convention filter
      #@convention_id = (params[:convention] && params[:convention][:convention_id]) ? params[:convention][:convention_id].to_i : 0
      #if @convention_id > 0
      #  c << ["convention_id = ? ", @convention_id.to_s]
      #end
    else
      @abbo = FeeConst::ROLE_ABBONATO
      c << ["role_id = ?", @abbo]

    end

    #@user_count = scope.count(:conditions => c.conditions)
    #@user_count = User.all.count(:conditions => c.conditions)
    #@user_pages = Paginator.new self, @user_count, @limit, params['page']
    #@offset ||= @user_pages.current.offset
    #@users =  scope.find :all,
    #@users =  User.find :all,
    #            :order => sort_clause,
    #            :conditions => c.conditions,
    #            :limit  =>  @limit,
    #            :offset =>  @offset

    @users =  User.find :all,
                :order => sort_clause,
                :conditions => c.conditions
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
      #app/models/mailer.rb  -> def deliver_fee(user, type, setting_text)   fee e fee_url
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
    redirect_to :controller => 'users', :action => 'edit', :id => @user, :tab => abbonamento
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

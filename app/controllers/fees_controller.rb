class FeesController < ApplicationController

  layout 'admin'

  before_filter :require_admin, :require_fee

  helper :sort
  include SortHelper
  include FeesHelper  #ROLE_XXX

  def index
    @num_users = User.all.count
    #Ruoli non sottoposti a controllo di abbonamento
    #  ROLE_MANAGER        = 1
    #BY INTERNAL ROLE
    #  ROLE_AUTHOR         = 2
    #  ROLE_COLLABORATOR   = 3
    #  ROLE_VIP            = 9
    @num_admin = User.all(:conditions => {:admin => 1}).count
    @num_redattori = User.all(:conditions => {:role_id => ROLE_AUTHOR}).count
    @num_collaboratori = User.all(:conditions => {:role_id => ROLE_COLLABORATOR}).count
    @num_invitati = User.all(:conditions => {:role_id => ROLE_VIP}).count
    @name_admin = User.all(:conditions => {:admin => 1})
    @name_redattori = User.all(:conditions => {:role_id => ROLE_AUTHOR})
    @name_collaboratori = User.all(:conditions => {:role_id => ROLE_COLLABORATOR})
    @name_invitati = User.all(:conditions => {:role_id => ROLE_VIP})
    #BY CLIENT ROLE
    #  ROLE_ABBONATO       = 5  #user.data_scadenza > (today - Setting.renew_days)
    #  ROLE_RENEW          = 8  #periodo prima della scadenza dipende da Setting.renew_days
    #  ROLE_REGISTERED     = 7  #periodo di prova durante Setting.register_days
    #  ROLE_EXPIRED        = 6  #user.data_scadenza < today
    #  ROLE_ARCHIVIED      = 4  #bloccato: puo uscire da questo stato solo manualmente ("Ha pagato", "invito di prova"=REGOISTERED)
    @num_abbonati = User.all(:conditions => {:role_id => ROLE_ABBONATO}).count
    @num_rinnovamento = User.all(:conditions => {:role_id => ROLE_RENEW}).count
    @num_registrati = User.all(:conditions => {:role_id => ROLE_REGISTERED}).count
    @num_scaduti = User.all(:conditions => {:role_id => ROLE_EXPIRED}).count
    @num_archiviati = User.all(:conditions => {:role_id => ROLE_ARCHIVIED}).count
    #Who pay?
    #BY PAYMENTS PRIVATE or CROSS ORGANIZATION
    @num_organismi = CrossOrganization.all.count
    @num_power_user = User.all(:conditions => {:power_user => 1}).count
    @num_members =  User.all(:conditions => {:cross_organization_id => !nil}).count
    @num_privati = User.all(:conditions => {:cross_organization_id => nil}).count

    #User member of ASSOCIATION
    @num_Associations =  Asso.all.count
    @num_Associated =  User.all(:conditions => {:asso_id => !nil}).count
    #@msg[] << ""
    if params['verify'].to_i == 1
      @msg = ["---Verificazione degli utenti---"]
      #User.each do |user|
      #    existing_regions = Region.all()
      for usr in User.all() do
        if !usr.nil?
          str = "<b>" << usr.name << "</b>, code: " << usr.codice.to_s << ", data: " <<  usr.datascadenza.to_s << ", role: " <<  usr.role_id.to_s << ", Asso: " <<  usr.asso_id.to_s << "(" << usr.power_user.to_s << ")"
          @msg << str
          #@msg << (str << ", code: " << usr.codice << ", data: " <<  usr.datascadenza << ", role: " <<  usr.role_id << ", Asso: " <<  usr.asso_id << "(" << usr.power_user << ")")
        end
      end 
    end

  end
  
  def verifica
    #per ogni utente 
    # prendere codice utente e data scadenza
    # --> definire il ruolo
    
    # verificare il codice utente per determinare se 
    #  è un pagante o un privato
    
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
    @users = User.all(:conditions => {:role_id => ROLE_REGISTERED}, :include => :role)
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

end

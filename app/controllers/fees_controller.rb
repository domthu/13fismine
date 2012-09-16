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
    #  ROLE_ARCHIVIED      = 4  #bloccato: puo uscire da questo stato solo manualmente ("Ha pagato", "invito di prova"=REGISTERED)
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
        str = control_assign_role(usr)
        if !str.nil?
          @msg << str
        end
      end 
    end
  end
  
  #per ogni utente 
  # prendere codice utente e data scadenza
  # --> definire il ruolo
  # verificare il codice utente per determinare se 
  #  è un pagante o un privato
  def control_assign_role(user)
    
    if user.nil?
      return nil
    end 
    old_state = "<b>" << user.name << "</b>, code: " << user.codice.to_s 
    old_state << (user.datascadenza.nil? ?  "" : ", data: " <<  user.datascadenza.to_s) 
    old_state << ", role: " <<  user.role_id.to_s 
    #Association
    if (user.asso_id.nil?)
      old_state << ", NON ASSOCIATO"
    else
      old_state << ", Asso(" << user.asso_id.to_s << "): " << (user.asso.nil? ? "?Asso?" : user.asso.name)
    end
    #Cross Organization
    if (user.cross_organization_id.nil?)
      old_state << ", <b>&euro;PAGANTE&euro;</b>"
    else
      old_state << ", CrossOrg(" << user.cross_organization_id.to_s << "): " << (user.cross_organization.nil?  ? "?cross_organization?" : (user.cross_organization.name))
      #Organization
      org = user.cross_organization.organization_for_user(user)
      org2 = user.organization
      if org.nil? 
        if org2.nil? 
          old_state << ", !NO ORGANIZATION!"  
        else
          old_state << ", organization(user): " << org2.name  
        end
      else
        if org2.nil? 
          old_state << ", organization(cross): " << org.name  
        else
          #ok abbiamo trovato tutti due
          #verifichiamo solo che sono uguali
          if org.id != org2.id
            old_state << ", organization(cross<-PROBLEM->user): " << org.name << "(" << org.id << ")<-->"  << org2.name << "(" << org2.id << ")"  
          else
            old_state << ", organization(user&Cross): " << org.name  
          end
        end
      end
      old_state << ((user.power_user.nil? || !user.power_user) ? "" : "<span class='power_user'>[POWER]</span>")
    end 
    
    str = "" #nil
    #ARCHIVIATO --> 0 NON riceve nulla e non accede al sito Non si interragisce più. Non ricevono newsletter
    if !user.role_id.nil? && user.role_id == ROLE_ARCHIVIED
      #Utente con questo ruolo ne possono uscire solo MANUALMENTE quindi non trattare
      str = "<span class='archivied'>" << old_state << "</span>"
#    #control if not yet registered and waiting for approvment
#    elsif !user.role_id.nil? && user.role_id == ROLE_REGISTERED
#      #  ROLE_REGISTERED     = 7  #periodo di prova durante Setting.register_days
#      #TODO EXPIRALO se ha superato il numero di giorni previsti
#      today = Date.today
#      fee_deadline = user.created_on + Setting.register_days
#      if today < fee_deadline
#        str = ensure_role(user, ROLE_EXPIRED, "EXPIRED", "espirato", old_state)
#      else
#        #l'Utente registrato dispone ancora di alcuni giorni
#        #ROLE_EXPIRED        = 6  #user.data_scadenza < today
#        str = "<span class='registrato'>" << old_state << "</span>"
#      end 
#    elsif !user.role_id.nil? && user.role_id == ROLE_ARCHIVIED
#        str = "<b class='modified'>Codice utente non presente?=</b>"
    else
      #Controllo per Codice
      #TODO: La verifica per data scadenza ed altri verrà fatta altrove
      case user.codice
      #COLLABORATOR (REDATTORE) --> -1 e 9 e 1959
      when -1,9,1959
        str = ensure_role(user, ROLE_COLLABORATOR, "REDATTORE", "redattore", old_state)
      #INVITATI (GRATUITI) --> codice 8
      when 8
        str = ensure_role(user, ROLE_VIP, "INVITATO", "vip", old_state)
      #REGISTRATO --> 3      (il sistema dopo il periodo di prova da in automatico il ruolo SCADUTO)
      when 3
        str = ensure_role(user, ROLE_REGISTERED, "REGISTRATO", "registrato", old_state)
      #ABBONATO_PRIVATO --> 6 e 7
      when 6,7
        #TODO control expiration
        str = ensure_fee_validity(user, nil, old_state)
      when 2,3,4
        #TODO control expiration
        str = ensure_fee_validity(user, nil, old_state)
      else
        #ABBONATO_AFFILIATO --> codice di un organismo
        #organismo_associato = Asso.find(user.codice);
        org = user.organization
        if org.nil?
          str = "<b style='color:red;'>Codice NON conosciuto " << user.codice.to_s << "</b> "
          #SCADUTO  --> 2 e 4 e 5 + Tutti altri casi    (dopo la data di scadenza)  possono ancora ricevere newsletter. possono ancora vedere le cose 
          #  ROLE_EXPIRED        = 6  #user.data_scadenza < today
          str << ensure_role(user, ROLE_EXPIRED, "EXPIRED", "espirato", old_state)
        else
          #esiste l'organizzazione pagante
          str << ensure_fee_validity(user, org, old_state)
        end
      end
    end
    #solo se cambiato
    return str
  end 
#NOTA: Distinguire Privati paganti ed Org.Asso paganti

  def ensure_fee_validity(user, organization, old_state)
    validity = 3
    str = ""
    data_scadenza = organization.nil? ? \
        (user.data.nil? ? user.data : user.datascadenza) \
        : organization.data_scadenza
    if data_scadenza.nil? # TODO or data empty
        #  ROLE_EXPIRED        = 6  #user.data_scadenza < today
        str = ", <b style='color:orange'>Scadenza NULL</b>"
        str << ensure_role(user, ROLE_EXPIRED, "EXPIRED", "espirato", old_state)
    else
      str = ", Scadenza: " << data_scadenza.strftime("%y%m%d%H%M ")
      today = Date.today
      renew_deadline = data_scadenza - Setting.renew_days
      if (today <= renew_deadline)
        str << ensure_role(user, ROLE_ABBONATO, "ABBONATO", "abbonato", old_state)
      elsif (today <= data_scadenza)
        #IN_SCADENZA           (controllo sulla data di scadenza del privato o dell'Organismo Associato)
        #  ROLE_RENEW          = 8  #periodo prima della scadenza dipende da Setting.renew_days
        str << ensure_role(user, ROLE_RENEW, "ABBONATO in scadenza", "inscadenza", old_state)
      else
        #  ROLE_EXPIRED        = 6  #user.data_scadenza < today
        str << ensure_role(user, ROLE_EXPIRED, "EXPIRED", "espirato", old_state)
      end
    end
    return str
  end
    
#css
#.registrato{}
#.abbonato{}
#.scadenza{}
#.espirato{}
#.archivied{}
#.registrato{}
    
  def ensure_role(user, roleid, role_label, role_css, old_state)
    str = ""
    if user.role_id.nil? || user.role_id != roleid
      user.role_id = roleid
      old_role = user.role.nil? ?  "?" : user.role.name
      str << "<span class='" << role_css << " modified'> " << old_role <<  " --> " << role_label << ". "
      str << old_state << "</span>"
      user.save()
    else
      str << "<span class='" << role_css << " unchanged'> ok: " << old_state << "</span>"
    end 
    return str
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

class FeesController < ApplicationController

  layout 'admin'

  before_filter :require_admin, :require_fee

  helper :sort
  include SortHelper
  include FeesHelper  #ROLE_XXX  gedate
  include ActionView::Helpers::DateHelper


  def index
    #@msg[] << ""
    if params['verify'].to_i == 1
      @msg = ["---Verificazione degli utenti---"]
      #User.each do |user|
      #    existing_regions = Region.all()
      for usr in User.all(:limit => 20) do
        str = control_assign_role(usr)
        if !str.nil?
          @msg << str
        end
      end 
    end

    @num_users = User.all.count
    #Ruoli non sottoposti a controllo di abbonamento
    #  ROLE_MANAGER        = 1
    #BY INTERNAL ROLE
    #  ROLE_AUTHOR         = 2
    #  ROredattoriLE_COLLABORATOR   = 3
    #  ROLE_VIP            = 9
    @num_admin = User.all(:conditions => {:admin => 1}).count
    @name_admin = User.all(:conditions => {:admin => 1})

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
    @num_organismi = CrossOrganization.all.count
    #@num_power_user = User.all(:conditions => {:power_user => 1}).count
    @num_power_user = User.all(:conditions => {:power_user => true}).count
    @num_members =  User.all(:conditions => {:cross_organization_id => !nil}).count
    @num_privati = User.all(:conditions => {:cross_organization_id => nil}).count

    #User member of ASSOCIATION
    @num_Associations =  Asso.all.count
    @num_Associated =  User.all(:conditions => {:asso_id => !nil}).count
  end
  
  #per ogni utente 
  # prendere codice utente e data scadenza
  # --> definire il ruolo
  # verificare il codice utente per determinare se 
  #  è un pagante o un privato
  def control_assign_role(_usr)
    
    if _usr.nil?
      return nil
    end 
    #SELECT `firstname`, `lastname`,`mail`,`id`,`codice`,`nome`,`asso_id`,`cross_organization_id`,`data`,`datascadenza` FROM `_usrs` where nome like '%PERUFFO MARCO%'
    old_state = "<b>(" <<  _usr.id.to_s << ")" 
    old_state << _usr.name << "</b>, "
    old_state << "code: " << _usr.codice.to_s 
    old_state << (_usr.datascadenza.nil? ?  "" : ", data: " <<  _usr.datascadenza.to_s) 
    old_state << ", role: " <<  _usr.role_id.to_s 
    #Association
    if (_usr.asso_id.nil?)
      old_state << ", <b>&euro; PAGANTE &euro;</b> NON ASSOCIATO utente scade " << getdate(_usr.datascadenza)
    else
      old_state << ", Asso(" << _usr.asso_id.to_s << "): " << (_usr.asso.nil? ? "?Asso?" : _usr.asso.name) << " org. scade " << getdate(_usr.asso.scadenza)
    end
    #control helper
    if _usr.scadenza.nil?
      old_state << ", --NO scad--"
    else
      old_state << ", scad[" << _usr.scadenza << "]"
    end 
    
    #Cross Organization
    if (_usr.cross_organization_id.nil?)
      old_state << ", senza affiliazione"
    else
      old_state << ", AFFILIATO CrossOrg(" << _usr.cross_organization_id.to_s << "): " << (_usr.cross_organization.nil?  ? "?cross_organization?" : (_usr.cross_organization.name))
      #control helper
      #  _usr.affiliato?
      #  _usr.affiliato_to
      old_state << ", Aff(" << _usr.affiliato?.to_s << ")[" << _usr.affiliato_to << "]"
      #Organization
      org = _usr.cross_organization.organization_for_user(_usr)
      org2 = _usr.organization
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
      old_state << ((_usr.power_user.nil? || !_usr.power_user) ? "" : "<span class='power_user'>[POWER]</span>")
    end 
    
    str = "" #nil
    #ARCHIVIATO --> 0 NON riceve nulla e non accede al sito Non si interragisce più. Non ricevono newsletter
    if !_usr.role_id.nil? && _usr.role_id == ROLE_ARCHIVIED
      #Utente con questo ruolo ne possono uscire solo MANUALMENTE quindi non trattare
      str = "<span class='archivied'>" << old_state << "</span>"
#    #control if not yet registered and waiting for approvment
#    elsif !_usr.role_id.nil? && _usr.role_id == ROLE_REGISTERED
#      #  ROLE_REGISTERED     = 7  #periodo di prova durante Setting.register_days
#      #TODO EXPIRALO se ha superato il numero di giorni previsti
#      today = Date.today
#      fee_deadline = _usr.created_on + Setting.register_days.to_i.days
#      if today < fee_deadline
#        str = ensure_role(_usr, ROLE_EXPIRED, "EXPIRED", "espirato", old_state)
#      else
#        #l'Utente registrato dispone ancora di alcuni giorni
#        #ROLE_EXPIRED        = 6  #_usr.data_scadenza < today
#        str = "<span class='registrato'>" << old_state << "</span>"
#      end 
#    elsif !_usr.role_id.nil? && _usr.role_id == ROLE_ARCHIVIED
#        str = "<b class='modified'>Codice utente non presente?=</b>"
    else
      if _usr.id == 1
        #NON FARE niente
        _usr.admin = true
        _usr.power_user = false
        _usr.role_id = -1
        str = ensure_role(_usr, ROLE_AUTHOR, "REDATTORE", "redattore", old_state)
      else
        #set default
        _usr.admin = false
        _usr.role_id = ROLE_EXPIRED
        #Controllo per Codice
        #TODO: La verifica per data scadenza ed altri verrà fatta altrove
        case _usr.codice
        #AUTHOR --> -1   o admin?
        #COLLABORATOR --> 9 e 1959
        when -1,9,1959
          #admin
          #-1 potere codice di amministrazione
          #if (_usr.codice == -1)
          #  _usr.admin = true
          #end
          #1959 codice anniversaire
          if (_usr.codice == 1959)
            _usr.admin = true
          end
          str = ensure_role(_usr, ROLE_AUTHOR, "REDATTORE", "redattore", old_state)

        #INVITATI (GRATUITI) --> codice 8
        when 8
          str = ensure_role(_usr, ROLE_VIP, "INVITATO", "vip", old_state)

        #REGISTRATO --> 3      (il sistema dopo il periodo di prova da in automatico il ruolo SCADUTO)
        when 3
          str = ensure_role(_usr, ROLE_REGISTERED, "REGISTRATO", "registrato", old_state)

        #ABBONATO_PRIVATO --> 6 e 7
        when 6,7
          #TODO control expiration
          str = ensure_fee_validity(_usr, nil, old_state)
          #control
          if !_usr.asso.nil?
            str << "<b style='color:red;'>codice(" << _usr.codice.to_s << ") PRIVATO pero ha un Asso(" << _usr.asso.to_s << ")</b> " 
          end

        when 2,4,5
          #TODO control expiration
          str = ensure_fee_validity(_usr, nil, old_state)

        else
          #ABBONATO_AFFILIATO --> codice di un organismo
          #organismo_associato = Asso.find(_usr.codice);
          org = _usr.organization
          if org.nil?
            str = "<b style='color:red;'>Codice NON conosciuto " << _usr.codice.to_s << "</b> "
            #SCADUTO  --> 2 e 4 e 5 + Tutti altri casi    (dopo la data di scadenza)  possono ancora ricevere newsletter. possono ancora vedere le cose 
            str << ensure_role(_usr, ROLE_EXPIRED, "EXPIRED", "espirato", old_state)
          else
            #esiste l'organizzazione pagante
            str << ensure_fee_validity(_usr, org, old_state)
          end
        end
      end
    end
    #solo se cambiato
    return str
  end 
#NOTA: Distinguire Privati paganti ed Org.Asso paganti
#  _usr.privato?
#  _usr.scadenza
#  _usr.affiliato?
#  _usr.affiliato_to


  def ensure_fee_validity(_usr, org_asso, old_state)
    str = ""
#    #3/1/01 105624 AM 	
#    clean__usr_data = _usr.data
#    #0000-00-00 00:00:00
#    final_data = _usr.datascadenza
#    if final_data.is_a?(Date)
#      final_data = final_data.to_date
#    else
#      (Date.parse(final_data) rescue nil)
#    end

#    if ((final_data.nil?) || (final_data.is_a?(Date) && (final_data.to_date.year == 0)))
#      #@date_from = Date.civil(@date_from.year, @date_from.month, 1)
#      #clean date?
#      docleaner = false;
#      begin    
#        data_scadenza = clean_user_data.to_date
#      rescue
#        docleaner = true;
#        data_scadenza = nil
#      end
#      
#      if docleaner
#        #need to clean the date
#        
#        if (_usr.data.nil?)
#          #set expired
#          _usr.data = Date.today.day.to_s << "/" << Date.today.month.to_s << "/" << Date.today.year.to_s
#          _usr.datascadenza = DateTime.today
#          str << ensure_role(_usr, ROLE_EXPIRED, "EXPIRED", "espirato", old_state)

#        #data like 
#        #2/25/01 64928 PM
#        #3/1/01 105624 AM 	
#        #3/11/01 121909 AM
#        #SELECT `firstname`, `lastname`,`mail`,`id`,`codice`,`nome`,`asso_id`,`cross_organization_id`,`data`,`datascadenza`
#        #FROM `users` where data is not null and data like '%m%'
#        #order by data
#	      elsif _usr.data.indexof("m") > 0
#          y = 
#          m = 
#          d =
#          _usr.data = Date.Civil(y,m,d)
#          _usr.datascadenza = Date.Civil(y,m,d)
#        #01/02/2006
#        elsif 
#          _usr.data = Date.parse(_usr.data)
#          _usr.datascadenza = _usr.data.to_date
#        end
#        #togliere PM ed altri
#      end
#    end
    data_scadenza = (org_asso.nil? || org_asso.scadenza.nil? || org_asso.scadenza.year == 0) ? \
        _usr.datascadenza : org_asso.scadenza
        
    if data_scadenza.nil? || !data_scadenza.is_a?(Date)
      data_scadenza = _usr.scadenza #Non tiene conto della gestionae del codice
    end

    if data_scadenza.nil? || !data_scadenza.is_a?(Date)
        #  ROLE_EXPIRED        = 6  #_usr.data_scadenza < today
        str = ", <b style='color:orange'>Scadenza " 
        if (data_scadenza.nil?)
          str = " NULL[" 
        else
          str = " DATA?" << data_scadenza << "[" 
        end
        str << "asso.id: " << (_usr.asso_id.nil? ? "" : ("(" << _usr.asso_id.to_s << ")--> " << ((_usr.asso.nil? || _usr.asso.scadenza.nil?) ? "No scadenza?" : _usr.asso.scadenza.to_s)))
        str << "/cross.id: " << (_usr.cross_organization_id.nil? ? "" : _usr.cross_organization_id.to_s)
        str << "/user.data: " << (_usr.data.nil? ? "" : _usr.data)
        str << "/user.scadenza" << (_usr.datascadenza.nil? ? " " : _usr.datascadenza.to_s)
        str << "]</b>"
        str << ensure_role(_usr, ROLE_EXPIRED, "EXPIRED", "espirato", old_state)
    else
      #tTODO data
      #Note that Time.zone.parse returns a DateTime, while appending the .utc gives you a Time.
      #scadenza = Time.zone.parse(data_scadenza) 
      #undefined method `parse' for nil:NilClass
      scadenza = data_scadenza.to_date
      str = ", Scadenza: " << scadenza.strftime("%y%m%d%H%M ")
      today = Date.today
      renew_deadline = scadenza - Setting.renew_days.to_i.days 
      if (today < renew_deadline)
        str << ensure_role(_usr, ROLE_ABBONATO, "ABBONATO", "abbonato", old_state)
      elsif (today < scadenza)
        #IN_SCADENZA           (controllo sulla data di scadenza del privato o dell'Organismo Associato)
        #  ROLE_RENEW          = 8  #periodo prima della scadenza dipende da Setting.renew_days
        str << ensure_role(_usr, ROLE_RENEW, "ABBONATO in scadenza", "inscadenza", old_state)
      else
        #  ROLE_EXPIRED        = 6  #_usr.data_scadenza < today
        str << ensure_role(_usr, ROLE_EXPIRED, "EXPIRED", "espirato", old_state)
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
    
  def ensure_role(_usr, roleid, role_label, role_css, old_state)
    str = ""
    if _usr.role_id.nil? || _usr.role_id != roleid
      old_role = _usr.role.nil? ?  "?" : _usr.role.name
      _usr.role_id = roleid
      str << "<span class='" << role_css << " modified'> " << old_role <<  " --> " << role_label << ". "
      str << old_state << "</span>"
      _usr.save()
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

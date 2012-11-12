class FeesController < ApplicationController

  layout 'admin'

  before_filter :require_admin, :require_fee
  #before_filter :find_user, :only => [:registrati, :associati, :privati, :archiviati, :scaduti]
  before_filter :get_statistics, :only => [:index, :registrati, :associati, :privati, :archiviati, :scaduti]



  helper :sort
  include SortHelper
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
      old_state << ", scad[" << _usr.scadenza.to_s << "]"
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
      if (!_usr.cross_organization.nil?)
        org = _usr.cross_organization.organization_for_user(_usr)
      end
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
#        str = ensure_role(_usr, ROLE_EXPIRED, "EXPIRED", old_state)
#      else
#        #l'Utente registrato dispone ancora di alcuni giorni
#        #ROLE_EXPIRED        = 6  #_usr.data_scadenza < today
#        str = "<span class='registrato'>" << old_state << "</span>"
#      end
#    elsif !_usr.role_id.nil? && _usr.role_id == ROLE_ARCHIVIED
#        str = "<b class='modified'>Codice utente non presente?=</b>"
    else
      #user.admin solo utente 1 e 1959
      if _usr.id == 1
        #NON FARE niente
        _usr.admin = true
        _usr.power_user = false
        _usr.role_id = -1
        str = ensure_role(_usr, ROLE_MANAGER, "MANAGER", old_state)
      else
        #set default
        _usr.admin = false
        _usr.role_id = ROLE_EXPIRED
        #Controllo per Codice
        #TODO: La verifica per data scadenza ed altri verrà fatta altrove
        case _usr.codice
        #AUTHOR --> -1   o admin?
        #COLLABORATOR --> 9 e 1959
        #REDATTORE (COLLABORATORE) --> -1 e 9 e 1959   (-1 superpotere)
        when -1
          str = "manager"
          #-1 potere codice di amministrazione
          if (_usr.power_user == false)
            str << "non era power_user"
            _usr.power_user = true
            #_usr.save()
          end
          str << ensure_role(_usr, ROLE_MANAGER, "MANAGER", old_state)

        when 1959 #codice anniversaire
          if (_usr.admin == false)
            str << "non era admin"
            _usr.admin = true
            #_usr.save()
          end
          str << ensure_role(_usr, ROLE_MANAGER, "MANAGER", old_state)

        when 9
          str = "author-collab"
          str  << ensure_role(_usr, ROLE_AUTHOR, "REDATTORE", old_state)

        #INVITATI (GRATUITI) --> codice 8
        when 8
          str = ensure_role(_usr, ROLE_VIP, "INVITATO", old_state)

        #REGISTRATO --> 3      (il sistema dopo il periodo di prova da in automatico il ruolo SCADUTO)
        when 3
          str = ensure_role(_usr, ROLE_REGISTERED, "REGISTRATO", old_state)

        #ABBONATO_PRIVATO --> 6 e 7
        #IN_SCADENZA (controllo sulla data di scadenza del privato)
        when 6,7
          #TODO control expiration
          str = ensure_fee_validity(_usr, nil, old_state)
          #control
          if !_usr.asso.nil?
            str << "<b style='color:red;'>codice(" << _usr.codice.to_s << ") PRIVATO pero ha un Asso(" << _usr.asso.to_s << ")</b> "
          end

        #SCADUTO  --> 2 e 4 e 5 + Tutti altri casi    (dopo la data di scadenza)  possono ancora ricevere newsletter. possono ancora vedere le cose
        when 2,4,5
          str << ensure_role(_usr, ROLE_EXPIRED, "EXPIRED", old_state)
          #str = ensure_fee_validity(_usr, nil, old_state)

          #ARCHIVIATO --> 0 NON riceve nulla e non accede al sito Non si interragisce più. Non ricevono newsletter
        when 0
          str << ensure_role(_usr, ROLE_ARCHIVIED, "ARCHIVIED", old_state)

        #ABBONATO_AFFILIATO --> codice di un organismo
        #IN_SCADENZA? (controllo sulla data di scadenza dell'Organismo Associato)
        else
          #ABBONATO_AFFILIATO --> codice di un organismo
          #organismo_associato = Asso.find(_usr.codice);
          org = _usr.organization
          if org.nil?
            str = "<b style='color:red;'>Codice NON conosciuto " << _usr.codice.to_s << "</b> "
            #SCADUTO  --> 2 e 4 e 5 + Tutti altri casi    (dopo la data di scadenza)  possono ancora ricevere newsletter. possono ancora vedere le cose
            str << ensure_role(_usr, ROLE_EXPIRED, "EXPIRED", old_state)
          else
            #esiste l'organizzazione pagante
            str << ensure_fee_validity(_usr, org, old_state)
          end
        end
      end
    end
    #solo se cambiatoe
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
#          str << ensure_role(_usr, ROLE_EXPIRED, "EXPIRED", old_state)

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
      data_scadenza = _usr.scadenza #Non tiene conto della gestione del codice
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
        str << "/user.data: " << (_usr.data.nil? ? "" : _usr.data.to_s)
        str << "/user.scadenza" << (_usr.datascadenza.nil? ? " " : _usr.datascadenza.to_s)
        str << "]</b>"
        str << ensure_role(_usr, ROLE_EXPIRED, "EXPIRED", old_state)
    else
      #TODO data
      #Note that Time.zone.parse returns a DateTime, while appending the .utc gives you a Time.
      #scadenza = Time.zone.parse(data_scadenza)
      #undefined method `parse' for nil:NilClass
      scadenza = data_scadenza.to_date
      #str = ", Scadenza: " << scadenza.strftime("%y%m%d%H%M ")
      str = ", Scadenza: " << scadenza.strftime("%Y %b(%m) %d")
      today = Date.today
      renew_deadline = scadenza - Setting.renew_days.to_i.days
      if (today < renew_deadline)
        str << ensure_role(_usr, ROLE_ABBONATO, "ABBONATO", old_state)
      elsif (today < scadenza)
        #IN_SCADENZA           (controllo sulla data di scadenza del privato o dell'Organismo Associato)
        #  ROLE_RENEW          = 8  #periodo prima della scadenza dipende da Setting.renew_days
        str << ensure_role(_usr, ROLE_RENEW, "ABBONATO in scadenza", old_state)
      else
        #  ROLE_EXPIRED        = 6  #_usr.data_scadenza < today
        str << ensure_role(_usr, ROLE_EXPIRED, "EXPIRED", old_state)
      end
    end
    return str
  end

  def ensure_role(_usr, roleid, role_label, old_state)
    str = ""
    if _usr.role_id.nil? || _usr.role_id != roleid
      old_role = _usr.role.nil? ?  "?" : _usr.role.name
      _usr.role_id = roleid
      str << "<span class='" << get_role_css(_usr) << " modified'> " << old_role <<  " --> " << role_label << ". "
      str << old_state << "</span>"
      _usr.save()
    else
      str << "<span class='" << get_role_css(_usr) << " unchanged'> ok: " << old_state << "</span>"
    end
    return str
  end

end

module FeesHelper
  include ActionView::Helpers::DateHelper
  #include ApplicationHelper   NO utc? in format_time
  #include UsersHelper #def change_status_link(user)   #Kappao cyclic include detected

  #ruoli che non sono sottoposti ad controllo di scadenza
  #NOTA BENE usare i permissi per quesi casi
  ROLE_MANAGER        = 3  #Manager<br />
  ROLE_AUTHOR         = 4  #Redattore  <br />
  #ROLE_COLLABORATOR   = 4  #ROLE_REDATTORE   autore, redattore e collaboratore tutti uguali<br />
  ROLE_VIP            = 10 #Invitato Gratuito<br />

  ROLE_ABBONATO       = 6  #Abbonato user.data_scadenza > (today - Setting.renew_days)<br />
  ROLE_REGISTERED     = 9  #Ospite periodo di prova durante Setting.register_days<br />
  ROLE_RENEW          = 11  #Rinnovo: periodo prima della scadenza dipende da Setting.renew_days<br />
  ROLE_EXPIRED        = 7  #Scaduto: user.data_scadenza < today<br />
  ROLE_ARCHIVIED      = 8  #Archiviato: bloccato: puo uscire da questo stato solo manualmente ("Ha pagato", "invito di prova"=REGISTERED, cambio ruolo...)<br />

#La gestione dipende del ruolo
# Se sottoposto a controllo abbonamento
#  map.permission :fee_control, :welcome => :index, :require => :loggedin, :public => true


#Altre permissione per chi dipende della gestione del ruolo/abboanmento
#  map.permission :access_back_end, :welcome => :index, :require => :loggedin
#  map.permission :front_end_quesito, :editorial => :quesito_nuovo, :require => :loggedin

  #generate a string
  def getdate(data)
    if data.nil?
      return "?"
    elsif !data.is_a?(Date)
      return "?.." << data.to_s
    else
      #return data.to_date.strftime("%y%m%d%H%M ")
      return data.to_date.strftime("%Y %b(%m) %d")
    end
  end

  def fee_roles_options_for_select(selected)
    options_for_select([[l(:label_all), ''],
                        ["#{l(:role_manager)}", "#{ROLE_MANAGER.to_i}"],
                        ["#{l(:role_author)}", "#{ROLE_AUTHOR.to_i}"],
                        ["#{l(:role_vip)}", "#{ROLE_VIP.to_i}"],
                        ["#{l(:role_abbonato)}", "#{ROLE_ABBONATO.to_i}"],
                        ["#{l(:role_registered)}", "#{ROLE_REGISTERED.to_i}"],
                        ["#{l(:role_renew)}", "#{ROLE_RENEW.to_i}"],
                        ["#{l(:role_expired)}", "#{ROLE_EXPIRED.to_i}"],
                        ["#{l(:role_archivied)}", "#{ROLE_ARCHIVIED.to_i}"]
                        ], selected)
  end
  #  def change_status_link(user)
  def change_role_status_link(user)
    url = {:controller => 'fees', :action => 'update_role', :id => user, :page => params[:page], :role_id => params[:role_id]}

    if user.locked?
    elsif user.registered?
      link_to l(:button_activate), url.merge(:user => {:status => User::STATUS_ACTIVE}), :method => :put, :class => 'icon icon-unlock'
    elsif user != User.current
      link_to l(:button_lock), url.merge(:user => {:status => User::STATUS_LOCKED}), :method => :put, :class => 'icon icon-lock'
    end
#    ROLE_MANAGER        = 3  #Manager<br />
#    ROLE_AUTHOR         = 4  #Redattore  <br />
#    ROLE_VIP            = 10 #Invitato Gratuito<br />
#    ROLE_ABBONATO       = 6  #Abbonato user.data_scadenza > (today - Setting.renew_days)<br />
#    ROLE_REGISTERED     = 9  #Ospite periodo di prova durante Setting.register_days<br />
#    ROLE_RENEW          = 11  #Rinnovo: periodo prima della scadenza dipende da Setting.renew_days<br />
#    ROLE_EXPIRED        = 7  #Scaduto: user.data_scadenza < today<br />
#    ROLE_ARCHIVIED

    case user.role_id
      #ROLE_MANAGER  --> Admin
      when 3
        link_to l(:button_unlock), url.merge(:user => {:role_id => ROLE_MANAGER}), :method => :put, :class => 'icon icon-man'
      #ROLE_AUTHOR  -->
      when 4
        link_to l(:button_unlock), url.merge(:user => {:role_id => ROLE_MANAGER}), :method => :put, :class => 'icon icon-auth'
      #ROLE_VIP  -->
      when 10
        link_to l(:button_unlock), url.merge(:user => {:role_id => ROLE_MANAGER}), :method => :put, :class => 'icon icon-vip'
      #ROLE_ABBONATO  --> ROLE_RENEW
      when 6
        link_to l(:button_unlock), url.merge(:user => {:role_id => ROLE_MANAGER}), :method => :put, :class => 'icon icon-abbo'
      #ROLE_REGISTERED  -->
      when 9
        link_to l(:button_unlock), url.merge(:user => {:role_id => ROLE_MANAGER}), :method => :put, :class => 'icon icon-reg'
      #ROLE_RENEW  -->
      when 11
        link_to l(:button_unlock), url.merge(:user => {:role_id => ROLE_MANAGER}), :method => :put, :class => 'icon icon-renew'
      #ROLE_EXPIRED  --> ROLE_ABBONATO
      when 7
        link_to l(:button_unlock), url.merge(:user => {:role_id => ROLE_MANAGER}), :method => :put, :class => 'icon icon-exp'
      #ROLE_ARCHIVIED  --> ?ROLE_EXPIRED

      when 8
        link_to l(:button_unlock), url.merge(:user => {:role_id => ROLE_MANAGER}), :method => :put, :class => 'icon icon-arc'
      else
        return ""
    end
  end


#/*Fee Roles*/
#.icon-man { background-image: url(../images/delete.png); }
#.icon-auth { background-image: url(../images/delete.png); }
#.icon-vip { background-image: url(../images/delete.png); }
#.icon-abbo { background-image: url(../images/delete.png); }
#.icon-reg { background-image: url(../images/delete.png); }
#.icon-renew { background-image: url(../images/delete.png); }
#.icon-exp { background-image: url(../images/delete.png); }
#.icon-arc { background-image: url(../images/delete.png); }
  def get_status_role(user)
    str = ""
    if Setting.fee?
      str += "<span class='"
      str += get_role_css(user)
      str += "'>"
      str += user.role.name
      str += "</span>"
    end
    return str
  end

  def get_role_css(user)
    case user.role_id
      #ROLE_MANAGER
      when 3
        return "icon icon-man"
      #ROLE_AUTHOR
      when 4
        return "icon icon-auth"
      #ROLE_VIP
      when 10
        return "icon icon-vip"
      #ROLE_ABBONATO
      when 6
        return "icon icon-abbo"
      #ROLE_REGISTERED
      when 9
        return "icon icon-reg"
      #ROLE_RENEW
      when 11
        return "icon icon-renew"
      #ROLE_EXPIRED
      when 7
        return "icon icon-exp"
      #ROLE_ARCHIVIED
      when 8
        return "icon icon-arc"
      else
        return ""
    end
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
    data_scadenza = _usr.scadenza

    if data_scadenza.nil?
      data_scadenza = _usr.datascadenza #esamina questa stringa
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
      str = ", Scadenza: " << getdate(scadenza)
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

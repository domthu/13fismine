module FeeConst

  TESTCONSTANT = 3
  #ruoli che non sono sottoposti ad controllo di scadenza
  #NOTA BENE usare i permissi per quesi casi
  ROLE_MANAGER        = 3  #Manager<br />
  ROLE_AUTHOR         = 4  #Redattore  <br />
  #ROLE_COLLABORATOR   = 4  #ROLE_REDATTORE   autore, redattore e collaboratore tutti uguali<br />
  ROLE_VIP            = 10 #Invitato Gratuito<br />

  ROLE_ABBONATO       = 6  #Abbonato user.data_scadenza > (today - Setting.renew_days)<br />
  ROLE_REGISTERED     = 9  #Ospite periodo di prova durante Setting.register_days<br />
  ROLE_RENEW=11
  #Rinnovo: periodo prima della scadenza dipende da Setting.renew_days<br />
  ROLE_EXPIRED=7
  #Scaduto: user.data_scadenza < today<br />
  ROLE_ARCHIVIED=8
  #Archiviato: bloccato: puo uscire da questo stato solo manualmente ("Ha pagato", "invito di prova"=REGISTERED, cambio ruolo...)<br />

end

module FeesHelper
  include ActionView::Helpers::DateHelper

  #include ApplicationHelper   NO utc? in format_time
  #include UsersHelper #def change_status_link(user)   #Kappao cyclic include detected

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
                        ["#{l(:role_manager)}", "#{FeeConst::ROLE_MANAGER.to_i}"],
                        ["#{l(:role_author)}", "#{FeeConst::ROLE_AUTHOR.to_i}"],
                        ["#{l(:role_vip)}", "#{FeeConst::ROLE_VIP.to_i}"],
                        ["#{l(:role_abbonato)}", "#{FeeConst::ROLE_ABBONATO.to_i}"],
                        ["#{l(:role_registered)}", "#{FeeConst::ROLE_REGISTERED.to_i}"],
                        ["#{l(:role_renew)}", "#{FeeConst::ROLE_RENEW.to_i}"],
                        ["#{l(:role_expired)}", "#{FeeConst::ROLE_EXPIRED.to_i}"],
                        ["#{l(:role_archivied)}", "#{FeeConst::ROLE_ARCHIVIED.to_i}"]
                        ], selected)
  end
  #  def change_status_link(user)
  def change_role_status_link(user)
    str = ""
    url = {:controller => 'fees', :action => 'update_role', :id => user, :page => params[:page], :role_id => params[:role_id]}

    if user.locked?
    elsif user.registered?
      str += link_to l(:button_activate), url.merge(:user => {:status => User::STATUS_ACTIVE}), :method => :put, :class => 'icon icon-unlock'
    elsif user != User.current
      str += link_to l(:button_lock), url.merge(:user => {:status => User::STATUS_LOCKED}), :method => :put, :class => 'icon icon-lock'
    end
#    FeeConst::ROLE_MANAGER        = 3  #Manager<br />
#    FeeConst::ROLE_AUTHOR         = 4  #Redattore  <br />
#    FeeConst::ROLE_VIP            = 10 #Invitato Gratuito<br />
#    FeeConst::ROLE_ABBONATO       = 6  #Abbonato user.data_scadenza > (today - Setting.renew_days)<br />
#    FeeConst::ROLE_REGISTERED     = 9  #Ospite periodo di prova durante Setting.register_days<br />
#    FeeConst::ROLE_RENEW          = 11  #Rinnovo: periodo prima della scadenza dipende da Setting.renew_days<br />
#    FeeConst::ROLE_EXPIRED        = 7  #Scaduto: user.data_scadenza < today<br />
#    FeeConst::ROLE_ARCHIVIED
    case user.role_id

      #FeeConst::ROLE_MANAGER  --> Admin
      when 3
        str += link_to l(:button_admin), url.merge(:user => {:admin => 1}), :method => :put, :class => 'icon icon-admin'

      #FeeConst::ROLE_AUTHOR  --> FeeConst::ROLE_MANAGER
      when 4
        str += link_to l(:button_manager), url.merge(:user => {:role_id => FeeConst::ROLE_MANAGER}), :method => :put, :class => 'icon icon-man'

      #FeeConst::ROLE_VIP  --> FeeConst::ROLE_AUTHOR
      #FeeConst::ROLE_VIP  --> FeeConst::ROLE_ABBONATO
      when 10
        str += link_to( l(:button_author), url.merge(:user => {:role_id => FeeConst::ROLE_AUTHOR}), :method => :put, :class => 'icon icon-auth') + link_to( l(:button_abbonato), url.merge(:user => {:role_id => FeeConst::ROLE_ABBONATO}), :method => :put, :class => 'icon icon-abbo')

      #FeeConst::ROLE_ABBONATO  --> FeeConst::ROLE_RENEW
      #FeeConst::ROLE_ABBONATO  --> FeeConst::ROLE_EXPIRED
      #FeeConst::ROLE_ABBONATO  --> FeeConst::ROLE_VIP
      when 6
        str += link_to( l(:button_renew), url.merge(:user => {:role_id => FeeConst::ROLE_RENEW}), :method => :put, :class => 'icon icon-renew') + link_to( l(:button_expired), url.merge(:user => {:role_id => FeeConst::ROLE_EXPIRED}), :method => :put, :class => 'icon icon-exp') + link_to( l(:button_vip), url.merge(:user => {:role_id => FeeConst::ROLE_VIP}), :method => :put, :class => 'icon icon-vip')

      #FeeConst::ROLE_REGISTERED  --> FeeConst::ROLE_ABBONATO
      #FeeConst::ROLE_REGISTERED  --> FeeConst::ROLE_EXPIRED
      #link_to( l(:button_registered), url.merge(:user => {:role_id => FeeConst::ROLE_REGISTERED}), :method => :put, :class => 'icon icon-reg')
      when 9
        str += link_to( l(:button_abbonato), url.merge(:user => {:role_id => FeeConst::ROLE_ABBONATO}), :method => :put, :class => 'icon icon-abbo') + link_to( l(:button_expired), url.merge(:user => {:role_id => FeeConst::ROLE_EXPIRED}), :method => :put, :class => 'icon icon-exp')

      #FeeConst::ROLE_RENEW  --> FeeConst::ROLE_ABBONATO
      #FeeConst::ROLE_RENEW  --> FeeConst::ROLE_EXPIRED
      when 11
        str += link_to( l(:button_abbonato), url.merge(:user => {:role_id => FeeConst::ROLE_ABBONATO}), :method => :put, :class => 'icon icon-abbo') + link_to( l(:button_expired), url.merge(:user => {:role_id => FeeConst::ROLE_EXPIRED}), :method => :put, :class => 'icon icon-exp')

      #FeeConst::ROLE_EXPIRED  --> FeeConst::ROLE_ABBONATO
      #FeeConst::ROLE_EXPIRED  --> FeeConst::ROLE_ARCHIVIED
      when 7
        str += link_to( l(:button_abbonato), url.merge(:user => {:role_id => FeeConst::ROLE_ABBONATO}), :method => :put, :class => 'icon icon-abbo') + link_to( l(:button_archivied), url.merge(:user => {:role_id => FeeConst::ROLE_ARCHIVIED}), :method => :put, :class => 'icon icon-arc')

      #FeeConst::ROLE_ARCHIVIED  --> ?FeeConst::ROLE_EXPIRED
      when 8
        str += link_to( l(:button_expired), url.merge(:user => {:role_id => FeeConst::ROLE_EXPIRED}), :method => :put, :class => 'icon icon-exp')
      else
        str += "Ruolo non conosciuto (" + user.role_id.to_s + ")"
    end
    return str
  end


#/*Fee Roles*/
#.icon-admin { background-image: url(../images/delete.png); }
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
      #FeeConst::ROLE_MANAGER
      when 3
        return "icon icon-man"
      #FeeConst::ROLE_AUTHOR
      when 4
        return "icon icon-auth"
      #FeeConst::ROLE_VIP
      when 10
        return "icon icon-vip"
      #FeeConst::ROLE_ABBONATO
      when 6
        return "icon icon-abbo"
      #FeeConst::ROLE_REGISTERED
      when 9
        return "icon icon-reg"
      #FeeConst::ROLE_RENEW
      when 11
        return "icon icon-renew"
      #FeeConst::ROLE_EXPIRED
      when 7
        return "icon icon-exp"
      #FeeConst::ROLE_ARCHIVIED
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

    #str = "DDDDDDD==" + FeeConst::ROLE_MANAGER.to_s + "=="
    #return str

    if _usr.nil?
      return nil
    end
    #SELECT `firstname`, `lastname`,`mail`,`id`,`codice`,`nome`,`asso_id`,`cross_organization_id`,`data`,`datascadenza` FROM `_usrs` where nome like '%PERUFFO MARCO%'
    old_state = "<b>(id: " +  _usr.id.to_s + ")" +
      _usr.name + "</b>, " + "code: " + _usr.codice.to_s +
      (_usr.datascadenza.nil? ?  "" : ", data: " +  _usr.datascadenza.to_s) +
      ", role: " +  _usr.role_id.to_s
    #control helper
    if _usr.scadenza.nil?
      old_state << ", --NO scad--"
    else
      old_state << ", scad[" << _usr.scadenza.to_s << "]"
    end

    str = "" #nil
    #ARCHIVIATO --> 0 NON riceve nulla e non accede al sito Non si interragisce più. Non ricevono newsletter
    #if !_usr.role_id.nil? && _usr.role_id == FeeConst::ROLE_ARCHIVIED
    if 1 == 0
      #Utente con questo ruolo ne possono uscire solo MANUALMENTE quindi non trattare
      str = "<span class='archivied'>" << old_state << "</span>"
#    #control if not yet registered and waiting for approvment
#    elsif !_usr.role_id.nil? && _usr.role_id == FeeConst::ROLE_REGISTERED
#      #  FeeConst::ROLE_REGISTERED     = 7  #periodo di prova durante Setting.register_days
#      #TODO EXPIRALO se ha superato il numero di giorni previsti
#      today = Date.today
#      fee_deadline = _usr.created_on + Setting.register_days.to_i.days
#      if today < fee_deadline
#        str = ensure_role(_usr, FeeConst::ROLE_EXPIRED, "EXPIRED", old_state)
#      else
#        #l'Utente registrato dispone ancora di alcuni giorni
#        #FeeConst::ROLE_EXPIRED        = 6  #_usr.data_scadenza < today
#        str = "<span class='registrato'>" << old_state << "</span>"
#      end
#    elsif !_usr.role_id.nil? && _usr.role_id == FeeConst::ROLE_ARCHIVIED
#        str = "<b class='modified'>Codice utente non presente?=</b>"
    else
      #user.admin solo utente 1 e 1959
      if _usr.id == 1
        #NON FARE niente
        _usr.admin = true
        _usr.power_user = false
        _usr.role_id = -1
        str = ensure_role(_usr, FeeConst::ROLE_MANAGER, "MANAGER", old_state)
      else
        #set default
        _usr.admin = false
        _usr.role_id = FeeConst::ROLE_EXPIRED
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
          str << ensure_role(_usr, FeeConst::ROLE_MANAGER, "MANAGER", old_state)

        when 1959 #codice anniversaire
          if (_usr.admin == false)
            str << "non era admin"
            _usr.admin = true
            #_usr.save()
          end
          str << ensure_role(_usr, FeeConst::ROLE_MANAGER, "MANAGER", old_state)

        when 9
          str = "author-collab"
          str  << ensure_role(_usr, FeeConst::ROLE_AUTHOR, "REDATTORE", old_state)

        #INVITATI (GRATUITI) --> codice 8
        when 8
          str = ensure_role(_usr, FeeConst::ROLE_VIP, "INVITATO", old_state)

        #REGISTRATO --> 3      (il sistema dopo il periodo di prova da in automatico il ruolo SCADUTO)
        when 3
          str = ensure_role(_usr, FeeConst::ROLE_REGISTERED, "REGISTRATO", old_state)

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
          str << ensure_role(_usr, FeeConst::ROLE_EXPIRED, "EXPIRED", old_state)
          #str = ensure_fee_validity(_usr, nil, old_state)

          #ARCHIVIATO --> 0 NON riceve nulla e non accede al sito Non si interragisce più. Non ricevono newsletter
        when 0
          str << ensure_role(_usr, FeeConst::ROLE_ARCHIVIED, "ARCHIVIED", old_state)

        #ABBONATO_AFFILIATO --> codice di un organismo
        #IN_SCADENZA? (controllo sulla data di scadenza dell'Organismo Associato)
        else
          #ABBONATO_AFFILIATO --> codice di un organismo associato
          #organismo_associato = Asso.find(_usr.codice);
          if _usr.asso.nil?
            str = "<b style='color:red;'>Codice NON conosciuto " << _usr.codice.to_s << "</b> "
            #SCADUTO  --> 2 e 4 e 5 + Tutti altri casi    (dopo la data di scadenza)  possono ancora ricevere newsletter. possono ancora vedere le cose
            str << ensure_role(_usr, FeeConst::ROLE_EXPIRED, "EXPIRED", old_state)
          else
            #esiste l'organismo associato pagante per questo utente
            str << ensure_fee_validity(_usr, _usr.asso, old_state)
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
    str = "<div style='color: blue;'> -" << FeeConst::TESTCONSTANT << "/"
    if org_asso.nil?
      data_scadenza = _usr.datascadenza
      str << "<b>&euro; PAGANTE &euro;</b> "
    else
      #Association
      str << "<b>NON PAGANTE</b> Asso(" << _usr.asso_id.to_s << "): " << _usr.asso.name
      #data_scadenza = _usr.asso.organization.data_scadenza
      data_scadenza = _usr.asso.scadenza
#      if data_scadenza.nil?
#        data_scadenza = _usr.datascadenza #esamina questa stringa
#      end
    end


    if data_scadenza.nil? || !data_scadenza.is_a?(Date)
        #  FeeConst::ROLE_EXPIRED        = 6  #_usr.data_scadenza < today
        str << ", <b style='color:orange'>Scadenza "
        if (data_scadenza.nil?)
          str << " NULL["
        else
          str << " DATA?" << data_scadenza << "["
        end
        str << "asso.id: " << (_usr.asso_id.nil? ? "" : ("(" << _usr.asso_id.to_s << ")--> " << ((_usr.asso.nil? || _usr.asso.scadenza.nil?) ? "/user.scadenza" : _usr.asso.scadenza.to_s)))
        #str << "/cross.id: " << (_usr.cross_organization_id.nil? ? "" : _usr.cross_organization_id.to_s)
        str << "/user.data: " << (_usr.data.nil? ? "" : _usr.data.to_s)
        str << "/user.datascadenza" << (_usr.datascadenza.nil? ? " " : _usr.datascadenza.to_s)
        str << "]</b>"
        str << ensure_role(_usr, FeeConst::ROLE_EXPIRED, "EXPIRED", old_state)
    else
      #TODO data
      #Note that Time.zone.parse returns a DateTime, while appending the .utc gives you a Time.
      #scadenza = Time.zone.parse(data_scadenza)
      #undefined method `parse' for nil:NilClass
      scadenza = data_scadenza.to_date
      if org_asso.nil?
        str << "<br /> Scadenza usr: " << getdate(scadenza)
      else
        str << "<br /> Scadenza ASSO: " << getdate(scadenza)
      end
      today = Date.today
      renew_deadline = scadenza - Setting.renew_days.to_i.days
      if (today < renew_deadline)
        str << ensure_role(_usr, FeeConst::ROLE_ABBONATO, "ABBONATO", old_state)
      elsif (today < scadenza)
        #IN_SCADENZA           (controllo sulla data di scadenza del privato o dell'Organismo Associato)
        #  FeeConst::ROLE_RENEW          = 8  #periodo prima della scadenza dipende da Setting.renew_days
        str << ensure_role(_usr, FeeConst::ROLE_RENEW, "ABBONATO in scadenza", old_state)
      else
        #  FeeConst::ROLE_EXPIRED        = 6  #_usr.data_scadenza < today
        str << ensure_role(_usr, FeeConst::ROLE_EXPIRED, "EXPIRED", old_state)
      end
    end
    str << "</div>"
    return str
  end

  def ensure_role(_usr, roleid, role_label, old_state)
    str = "roleid = [old " + _usr.role_id.to_s + "/ new" + roleid.to_s + "-->" + role_label + "] "
    if _usr.role_id.nil? || ( _usr.role_id != roleid )
      old_role = _usr.role.nil? ?  "?" : _usr.role.name
      _usr.role_id = roleid
      str << "<span class='" << get_role_css(_usr) << " modificato ruolo " << old_role <<  " --> " << role_label << ". "
      str << old_state << "</span>"
      _usr.save()
    else
      str << "<span class='" << get_role_css(_usr) << " unchanged'> ok ruolo non cambiato: " << old_state << "</span>"
    end
    return str
  end

end

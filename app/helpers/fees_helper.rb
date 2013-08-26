module FeeConst

  #ruoli che non sono sottoposti ad controllo di scadenza
  #NOTA BENE usare i permissi per quesi casi
  ROLE_ADMIN        = 0  #Admin<br />

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

  ROLES =[ROLE_MANAGER, ROLE_AUTHOR, ROLE_VIP, ROLE_ABBONATO, ROLE_REGISTERED, ROLE_RENEW, ROLE_EXPIRED, ROLE_ARCHIVIED]

  AUTHORED_ROLES =[ROLE_ADMIN, ROLE_MANAGER, ROLE_AUTHOR, ROLE_VIP, ROLE_ABBONATO, ROLE_REGISTERED, ROLE_RENEW]
  #ruoli che non possono essere cancelati dentro i ruoli di Redmine
  CAN_BACK_END_ROLES =[ROLE_ADMIN, ROLE_MANAGER, ROLE_AUTHOR]

  NEWSLETTER_ROLES =[ROLE_ABBONATO, ROLE_REGISTERED, ROLE_RENEW]
#  role_abbonato: Abbonato
#  role_registered: Registrato
#  role_renew: Rinnovo, In scadenza

  EDIZIONE_KEY = "e-" #Identificatore

  #QUESITO_ID = 15
  #QUESITO_KEY = "e-quesiti"
  QUESITO_ID = 1
  QUESITO_KEY = "sys-quesiti"

  TMENU_QUESITI = 7
  TMENU_NEWSPORT = 8
  TMENU_CONVEGNI = 9

  #User Profili  (voce menu => chi siamo)
  PROFILO_FS_COLLABORATORE = 1
  PROFILO_FS_RESPONSABILE = 2
  PROFILO_FS_DIRETTORE = 3
  PROFILO_FS_INVISIBILE = 0
  #---------------------
  #di sistema: Non si possono cancellare
  DEFAULT_SECTION = 5 #Approfondimenti
  DEFAULT_TOP_SECTION =  3 #Approfondimenti
  DEFAULT_TOP_MENU = 1 #Approfondimenti

  QUESITO_STATUS_WAIT =  1 #IN ATTESA - RICHIESTA
  QUESITO_STATUS_FAST_REPLY = 2 #RISPOSTA VELOCE TRAMITE NEWS
  QUESITO_STATUS_ISSUES_REPLY =  3 #RISPOSTA TRAMITE ARTICOLO/I
end

module FeesHelper
  include ActionView::Helpers::DateHelper
  include ApplicationHelper   #NO utc? in format_time
  #include UsersHelper #def change_status_link(user)   #Kappao cyclic include detected
  #per traduzione l(:role_author) --> undefined method `l'

  def link_to_top_section(ts)
    if ts.is_a?(TopSection)
      url = {:controller => 'top_sections', :action => 'edit', :id => ts.id}
      str = link_to("pippo", url)
      #link_to ts, edit_top_section_path(ts) undefined method
    else
      str = h(ts.to_s)
    end
    return str
  end

#La gestione dipende del ruolo
# Se sottoposto a controllo abbonamento
#  map.permission :fee_control, :welcome => :index, :require => :loggedin, :public => true


#Altre permissione per chi dipende della gestione del ruolo/abboanmento
#  map.permission :access_back_end, :welcome => :index, :require => :loggedin
#  map.permission :front_end_quesito, :editorial => :quesito_nuovo, :require => :loggedin

  #generate a string in ApplicationHelper
#  def getdate(data)
#    if data.nil?
#      return "?"
#    elsif !data.is_a?(Date)
#      return "?.." << data.to_s
#    else
#      #return data.to_date.strftime("%y%m%d%H%M ")
#      return data.to_date.strftime("%Y %b(%m) %d")
#    end
#  end

  #<%= select_tag 'block', "<option></option>" + options_for_select(@block_options), :id => "block-select" %>
  def fee_roles_options_for_select(selected)
    options_for_select([[l(:label_all), ''],
                        [l(:role_manager), FeeConst::ROLE_MANAGER.to_s],
                        [l(:role_author), FeeConst::ROLE_AUTHOR.to_s],
                        [l(:role_vip), FeeConst::ROLE_VIP.to_s],
                        [l(:role_abbonato), FeeConst::ROLE_ABBONATO.to_s],
                        [l(:role_registered), FeeConst::ROLE_REGISTERED.to_s],
                        [l(:role_renew), FeeConst::ROLE_RENEW.to_s],
                        [l(:role_expired), FeeConst::ROLE_EXPIRED.to_s],
                        [l(:role_archivied), FeeConst::ROLE_ARCHIVIED.to_s]
                        ], selected.to_s)
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
      when 6, 7
        str += link_to( l(:button_renew), url.merge(:user => {:role_id => FeeConst::ROLE_RENEW}), :method => :put, :class => 'icon icon-renew') + link_to( l(:button_expired), url.merge(:user => {:role_id => FeeConst::ROLE_EXPIRED}), :method => :put, :class => 'icon icon-exp') + link_to( l(:button_vip), url.merge(:user => {:role_id => FeeConst::ROLE_VIP}), :method => :put, :class => 'icon icon-vip')

      #FeeConst::ROLE_REGISTERED  --> FeeConst::ROLE_ABBONATO
      #FeeConst::ROLE_REGISTERED  --> FeeConst::ROLE_EXPIRED
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
        #TODO http://localhost:3000/fees/update_role/18113?role_id=&user[role_id]=9
        str += "Ruolo non conosciuto (" + user.role_id.to_s + ") " + link_to( l(:button_registered), url.merge(:user => {:role_id => FeeConst::ROLE_REGISTERED}), :method => :put, :class => 'icon icon-reg')
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
    #abbonamento_name = FeeConst::ROLES_NAMES[user.role_id].to_s
    #abbonamento_name = ROLES_NAMES[user.role_id].to_s
    abbonamento_name = get_abbonamento_name(user)
    return user_role_iconized(user, :size => "s", :icon_for => user.uicon, :text => abbonamento_name)
    #str = ""
    #if Setting.fee?
    #  str += "<span class='"
    #  str += get_role_css(user)
    #  str += "'>"
    #  str += user.role.name
    #  str += "</span>"
    #end
    #return str
  end

  def get_role_css(user)
    if user.is_a?(User)
      user_role_iconized(user, :size => "s", :icon_for => user.uicon, :text => '')
    else
      #TODO similare def uicon()
      case user #integer
        #FeeConst::ROLE_MANAGER
        when 3
          return "admin" #"icon icon-man"
        #FeeConst::ROLE_AUTHOR
        when 4
          return "man" #"icon icon-auth"
        #FeeConst::ROLE_VIP
        when 10
          return "vip" #"icon icon-vip"
        #FeeConst::ROLE_ABBONATO
        when 6
          return "abbo" #"icon icon-abbo"
        #FeeConst::ROLE_REGISTERED
        when 9
          return "reg" #"icon icon-reg"
        #FeeConst::ROLE_RENEW
        when 11
          return "renew" #"icon icon-renew"
        #FeeConst::ROLE_EXPIRED
        when 7
          return "exp" #"icon icon-exp"
        #FeeConst::ROLE_ARCHIVIED
        when 8
          return "arc" #"icon icon-arc"
        else
          return "question"
      end
    end
  end

  #ROLES_NAMES =[l(:role_manager), l(:role_author), l(:role_vip), l(:role_abbonato), l(:role_registered), l(:role_renew), l(:role_expired), l(:role_archivied)]
  def get_abbonamento_name(user)
    if user.is_a?(User)
      abbo = user.role_id
    else
      abbo = user
    end
    case abbo
      #FeeConst::ROLE_MANAGER
      when 3
       return l(:role_manager)

      #FeeConst::ROLE_AUTHOR
      when 4
        return l(:role_author_abrv)
      #FeeConst::ROLE_VIP
      when 10
        return l(:role_vip)
      #FeeConst::ROLE_ABBONATO
      when 6
        return l(:role_abbonato)
      #FeeConst::ROLE_REGISTERED
      when 9
        return l(:role_registered)
      #FeeConst::ROLE_RENEW
      when 11
        return l(:role_renew)
      #FeeConst::ROLE_EXPIRED
      when 7
        return l(:role_expired)
      #FeeConst::ROLE_ARCHIVIED
      when 8
        return l(:role_archivied)
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
    str = "<b class='" + get_role_css(_usr) +"'>(" +  _usr.id.to_s + ")" +
      _usr.name + "</b>, " + "code: " + _usr.codice.to_s + ", scadenza: " +
      (_usr.scadenza.nil? ?  ", --NO scad--" :  _usr.scadenza.to_s) +
      ", role(" +  _usr.role_id.to_s + "): " + _usr.role.name

    #ARCHIVIATO --> 0 NON riceve nulla e non accede al sito Non si interragisce più. Non ricevono newsletter
    if !_usr.role_id.nil? && _usr.role_id == FeeConst::ROLE_ARCHIVIED
    #if 1 == 0
      #Utente con questo ruolo ne possono uscire solo MANUALMENTE quindi non trattare
      str << "Utente con questo ruolo ne possono uscire solo MANUALMENTE quindi non trattare"
    else
      #user.admin solo utente 1 e 1959
      if _usr.id == 1
        #NON FARE niente
        _usr.admin = true
        _usr.power_user = false
        _usr.role_id = -1
        str << ensure_role(_usr, FeeConst::ROLE_MANAGER)
      else
        #set default
        _usr.admin = false
        _usr.role_id = FeeConst::ROLE_EXPIRED
        #Controllo per Codice
        #TODO: La verifica per data scadenza ed altri verrà fatta altrove
        case _usr.codice.to_i
        #AUTHOR --> -1   o admin?
        #COLLABORATOR --> 9 e 1959
        #REDATTORE (COLLABORATORE) --> -1 e 9 e 1959   (-1 superpotere)
        when -1
          str = "manager"
          #-1 potere codice di amministrazione
          if (_usr.power_user == false)
            str << "non era power_user"
            _usr.power_user = true
            _usr.save  #Kappao _usr.save()
          end
          str << ensure_role(_usr, FeeConst::ROLE_MANAGER)

        when 1959 #codice anniversaire
          if (_usr.admin == false)
            str << "non era admin"
            _usr.admin = true
            _usr.save  #Kappao _usr.save()
          end
          str << ensure_role(_usr, FeeConst::ROLE_MANAGER)

        when 9
          str = "author-collab"
          str << ensure_role(_usr, FeeConst::ROLE_AUTHOR)

        #INVITATI (GRATUITI) --> codice 8
        when 8
          str << ensure_role(_usr, FeeConst::ROLE_VIP)

        #REGISTRATO --> 3      (il sistema dopo il periodo di prova da in automatico il ruolo SCADUTO)
        when 3
          str << ensure_role(_usr, FeeConst::ROLE_REGISTERED)

        #ABBONATO_PRIVATO --> 6 e 7
        #IN_SCADENZA (controllo sulla data di scadenza del privato)
        when 6,7
          #TODO control expiration
          str << ensure_fee_validity(_usr, nil)
          #control
          if _usr.convention
            str << "<b style='color:red;'>codice(" << _usr.codice.to_s << ") PRIVATO pero coperto da orgasnismo convenzionato(" << _usr.convention.to_s << ")</b> "
          end

        #SCADUTO  --> 2 e 4 e 5 + Tutti altri casi    (dopo la data di scadenza)  possono ancora ricevere newsletter. possono ancora vedere le cose
        when 2,4,5
          str << ensure_role(_usr, FeeConst::ROLE_EXPIRED)
          #str << ensure_fee_validity(_usr, nil)

          #ARCHIVIATO --> 0 NON riceve nulla e non accede al sito Non si interragisce più. Non ricevono newsletter
        when 0
          str << ensure_role(_usr, FeeConst::ROLE_ARCHIVIED)

        #ABBONATO_AFFILIATO --> codice di un organismo
        #IN_SCADENZA? (controllo sulla data di scadenza dell'Organismo Associato)
        else
          #ABBONATO_AFFILIATO --> codice di un organismo associato
          #organismo_associato = Asso.find(_usr.codice);
          if _usr.convention.nil?
            str << " <b style='color:red;'>Codice NON conosciuto " << _usr.codice.to_s << "</b> "
            #SCADUTO  --> 2 e 4 e 5 + Tutti altri casi    (dopo la data di scadenza)  possono ancora ricevere newsletter. possono ancora vedere le cose
            str << ensure_role(_usr, FeeConst::ROLE_EXPIRED)
          else
            #esiste l'organismo associato pagante per questo utente
            str << ensure_fee_validity(_usr, _usr.convention)
          end
        end
      end
    end
    #solo se cambiatoe
    return str
  end

  def ensure_fee_validity(_usr, org_asso)
    str = "<div style='color: "

    if org_asso.nil?
      str += "green;'>"
      data_scadenza = _usr.datascadenza
      str << "<b>&euro; PAGANTE &euro;</b> "
    else
      #Association
      str += "blue;'>"
      str << "<b>NON PAGANTE</b> Asso(" << _usr.convention_id.to_s << "): " << smart_truncate(_usr.convention.name, 50)
      data_scadenza = _usr.convention.scadenza
#      if data_scadenza.nil?
#        data_scadenza = _usr.datascadenza #esamina questa stringa
#      end
    end


    if data_scadenza.nil? || !data_scadenza.is_a?(Date)
        #  FeeConst::ROLE_EXPIRED        = 6  #_usr.data_scadenza < today
        str << ", <b style='color:black'> Scadenza "
        if (data_scadenza.nil?)
          str << " NULL["
        else
          str << " Data elaborata " << data_scadenza.strftime("%Y-%m-%d") << " ["
        end
        str << "convention " << (_usr.convention_id.nil? ? " -no- " : ("(" << _usr.convention_id.to_s << ") " << ((_usr.convention.nil? || _usr.convention.scadenza.nil?) ? " scadenza " : _usr.convention.scadenza.strftime("%Y-%m-%d"))))
        str << "/user datascadenza: " << (_usr.datascadenza.nil? ? " null " : _usr.datascadenza.to_s)
        str << " (dal " << (_usr.data.nil? ? " null " : _usr.data.to_s)  << ")"
        str << "]</b>"
        str << ensure_role(_usr, FeeConst::ROLE_EXPIRED)
    else
      #TODO data
      #Note that Time.zone.parse returns a DateTime, while appending the .utc gives you a Time.
      #scadenza = Time.zone.parse(data_scadenza)
      #undefined method `parse' for nil:NilClass
      scadenza = data_scadenza.to_date
      today = Date.today
      renew_deadline = scadenza - Setting.renew_days.to_i.days
      if (today < renew_deadline)
        str << ensure_role(_usr, FeeConst::ROLE_ABBONATO)
      elsif (today < scadenza)
        #IN_SCADENZA           (controllo sulla data di scadenza del privato o dell'Organismo conventionciato)
        #  FeeConst::ROLE_RENEW          = 8  #periodo prima della scadenza dipende da Setting.renew_days
        str << ensure_role(_usr, FeeConst::ROLE_RENEW)
      else
        #  FeeConst::ROLE_EXPIRED        = 6  #_usr.data_scadenza < today
        str << ensure_role(_usr, FeeConst::ROLE_EXPIRED)
      end
    end
    str << "</div>"
    return str
  end

  def ensure_role(_usr, nextroleid)
    oldrole = User.find(_usr.id).role_id
    str = " [Ruolo da " + oldrole.to_s + " a " + nextroleid.to_s + "] "
    if _usr.role_id.nil? || ( oldrole != nextroleid )
      _usr.role_id = nextroleid
      #_usr.save  #Kappao _usr.save()
      if !_usr.valid?
        if !_usr.errors.empty? && _usr.errors.any?
          #@errors += @user.errors.join(', ') undefined method join
          if _usr.errors.full_messages
            str << "Errore incontrate: " << _usr.errors.full_messages.join('<br />')
          else
            str << "Errore incontrate: " << _usr.errors.join('<br />')
          end
        else
          str << "<span class='red " << get_role_css(User.find(_usr.id)) << "'> NON MODIFICATO!</span>"
        end
      else
        if _usr.save  #Kappao _usr.save()
          str << "<span class='" << get_role_css(User.find(_usr.id)) << "'> modificato ruolo!</span>"
        else
          str << "<span class='red " << get_role_css(User.find(_usr.id)) << "'> NON SALVATO!</span>"
        end
      end
    else
      str << " == Ruolo non cambiato"
    end
    return str
  end


end

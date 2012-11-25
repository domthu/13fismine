module FeesHelper

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
#  map.permission :front_end_quesito, :editorial => :poniquesito, :require => :loggedin

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

end

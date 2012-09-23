module FeesHelper

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
  
end

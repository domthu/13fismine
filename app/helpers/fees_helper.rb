module FeesHelper

  # Roles statuses
  ROLE_ARCHIVIED      = 4
  ROLE_ABBONATO       = 5
  ROLE_EXPIRED        = 6
  ROLE_REGISTERED     = 7  #periodo di prova durante Setting.register_days
  ROLE_RENEW          = 8  #periodo prima della scadenza dipende da Setting.renew_days
  ROLE_VIP            = 9

  #ruoli che non sono sottoposti ad controllo di scadenza
  #NOTA BENE usare i permissi per quesi casi 
  ROLE_MANAGER        = 1
  ROLE_AUTHOR         = 2
  ROLE_COLLABORATOR   = 3  #ROLE_REDATTORE

#La gestione dipende del ruolo
# Se sottoposto a controllo abbonamento
#  map.permission :fee_control, :welcome => :index, :require => :loggedin, :public => true


#Altre permissione per chi dipende della gestione del ruolo/abboanmento
#  map.permission :access_back_end, :welcome => :index, :require => :loggedin
#  map.permission :front_end_quesito, :editorial => :poniquesito, :require => :loggedin
end

class ServicesController < ApplicationController

#include EditorialHelper
include ApplicationHelper

  #Non usato perchè preferiamo una lista a discesa
  def Usertitle
    #Rails.logger.info("json Usertitle")
    @users = User.all(:limit => 5)
    if params[:term]
      #Rails.logger.info("json Usertitle #{params[:term]}")
      #sanitize string for only
      #, :distinct => 'titolo'    ArgumentError --> Unknown key(s): distinct
      @users = User.find(:all, :limit => 5, :conditions => ['titolo LIKE ?', "%#{params[:term]}%"])

#      @user = User.search params[:term],
#          :limit => 5,
#          :match_mode => :any,
#          :field_weights => { :name => 20, :description => 10, :reviews_content => 5 }
    end

    #ATTENZIONE Gestire la risposta vuota dal JQuery Autocomplete
    if (@users.nil? or @users.count < 1)
      return render :json => [{
        :label => "0",
        :value => "Non è stato trovato niente che corrisponde a -#{params[:term]}-"
      }]
    end

    #Rails.logger.info("json Usertitle (%s)" % @users)

#    render :json =>
#      @user.to_json(:only => [:email], :include => [:addresses])
    @json_users = @users.collect { |e|  {:value => "#{e.name}, #{e.mail}" , :label => "#{e.codice}"} }
    #@json_users = @users.collect { |e| e.name, e.login }
    render :json => @json_users.to_json
    #respond_to do |format|
    #  format.js{
    #    #render :text => "alert('hello')"
    #    render :json => @json_users.to_json
    #  }
    #end
  end

  def emailctrl
    #Rails.logger.info("json emailctrl")
    if params[:term] && params[:field]
      #Rails.logger.info("json emailctrl #{params[:term]} per field #{params[:field]}")
      case params[:field]
        when 'user_mail'
          @users = User.count(:conditions => ['mail = ?', "#{params[:term]}"])
        when 'user_login'
          @users = User.count(:conditions => ['login = ?', "#{params[:term]}"])
        else
          @users = nil
      end

    end

    #ATTENZIONE Gestire la risposta vuota dal JQuery Autocomplete
    if (!@users.nil? and @users > 0)
      return render :json => {
        :success => true,
        :unavailable => true,
        :msg => "è presente nel database (#{@users.to_s}) informazione che corrisponde a -#{params[:term]}-"
      }
    end

    render :json => { :success => true, :available => true }
  end

  def privacy
    render :template => "services/privacy", :layout => false
  end

  def condition
    #puts "condition"
    render :template => "services/condition", :layout => false
  end

  def zone
#//var urlzone = '<%= zone_path %>';
#//$('#extra_Town').autocomplete({
#//$('#extra_town').autocomplete({
#//    source:urlzone,
#//    select:function (event, ui) {
#//        if (ui.item) {
#//            //$('#user_Town').val(ui.item.Text);
#//            //$('#user_comune_id').val(ui.item.Value);
#//            $('#user_comune_id').val(ui.item.hiddenvalue);
#//        }
#//        return true;
#//    },
#//    minLength:2
#//}).data("autocomplete")._renderItem = function (ul, item) {
#//    return $("<li></li>")
#//            .data("item.autocomplete", item)
#//        //.append("<a id='" + item.Value + "'>" + item.Text + "</a>")
#//            .append("<a>" + item.label + "</a>")
#//            .appendTo(ul);
#//};
    s =  params[:term] ? params[:term].to_s : ""
    @towns = Comune.find(
      :all,
      :limit => 10,
      :include => [{:province => :region}],
      :select => "comunes.id as id, comunes.name as c_name, comunes.cap as c_cap, comunes.cod_fisco as c_cod_fisco, provinces.name as p_name, provinces.sigla as p_sigla, regions.name as r_name",
      :conditions => ['comunes.name LIKE ? or provinces.sigla LIKE ? or provinces.name LIKE ? or regions.name LIKE ?', "%#{s}%", "%#{s}%", "%#{s}%", "%#{s}%"],
      :order => 'comunes.name'
    )
    #:joins => [{:province => :region}],   --> INNER JOIN
    #:include --> LEFT OUTER JOIN
    #:select => "distinct Comune
    #:conditions => {:a => {:a1 => Time.now.midnight. ... Time.now}},
    #:group_users => "b.b2, c.c2"

    #ATTENZIONE Gestire la risposta vuota dal JQuery Autocomplete
    if (@towns.nil? or @towns.count < 1)
      return render :json => [{
        :label => "0",
        :value => "Nessuna città per la ricerca -#{s}-",
        :hiddenvalue => "0"
      }]
    end
    @json_towns = @towns.collect { |e|  {
      :label => "#{e.cap} #{e.name} (#{e.province.sigla}) [#{e.province.region.name}]",
      :value => "#{e.name} #{e.cap} (#{e.province.sigla})",
      :hiddenvalue => "#{e.id}"
      }
    }
      #:value => "#{e.c_cap} #{e.c_name} (#{e.p_sigla}) [#{e.r_name}]",
      #:label => "#{e.c_name}",
      #:hiddenvalue => "#{e.id}"
    render :json => @json_towns.to_json
  end

  #La ricerca puo provenire da una pagina di
  # Caso 1: top_menu e quindi multi top_section(s)
  # Caso 2: mono top_section
  def articolo_extend
    s =  params[:term] ? params[:term].to_s : ""
    page_limit =  params[:page_limit] ? params[:page_limit].to_i : 10
    pagina =  params[:page] ? params[:page].to_i : 1
    offset = pagina * page_limit;

    #def top_sezione --> @topsection
    top_section_id =  params[:top_section] ? params[:top_section].to_i : 0
    if top_section_id > 0
      #@topsection = TopSection.find_by_id(top_section_id)

      totale = Issue.all_public_fs.with_filter("top_sections.hidden_menu = 0 AND top_sections.id = " + top_section_id.to_s + " AND (issues.subject LIKE ? OR issues.description LIKE ?)", "%#{s}%", "%#{s}%").count()

      @art = Issue.all_public_fs.find(
        :all,
        :conditions => ['top_sections.hidden_menu = 0 AND top_sections.id = ? AND (issues.subject LIKE ? OR issues.description LIKE ?)', "#{top_section_id}", "%#{s}%", "%#{s}%"],
        :order => 'issues.due_date DESC',
        :limit => page_limit,
        :offset => offset
      )

    else
      #def top_menu --> @top_menu
      top_menu_id =  params[:top_menu] ? params[:top_menu].to_i : 0
      if top_menu_id > 0
        #@top_menu = TopMenu.find_by_id(top_menu_id) if top_menu_id > 0

        totale = Issue.all_public_fs.with_filter("top_sections.hidden_menu = 0 AND top_sections.top_menu_id = " + top_menu_id.to_s + " AND (issues.subject LIKE ? OR issues.description LIKE ?)", "%#{s}%", "%#{s}%").count()

        @art = Issue.all_public_fs.find(
          :all,
          :conditions => ['top_sections.hidden_menu = 0 AND top_sections.top_menu_id = ? AND (issues.subject LIKE ? OR issues.description LIKE ?)', "#{top_menu_id}", "%#{s}%", "%#{s}%"],
          :order => 'issues.due_date DESC',
          :limit => page_limit,
          :offset => offset
        )
      end
    end

    if (@art.nil? or @art.count < 1)
      if pagina > 1
        xmsg = "Ricerche (" + totale.to_s + ") per -#{s}- finite. "
      else
        xmsg = "Nessun articolo per la ricerca -#{s}-"
      end
      @json_art = [{
        :id => 0,
        :label => xmsg,
        :value => "",
        :url => ""
      }]
    else
      @json_art = @art.collect { |e|  {
        :id =>  "#{e.id}",
        #:label => highlight_tokens(truncate(e.subject, :length => 255), s),
        #:label => highlight_tokens_svc(e.subject, s),
        #:label => syntax_highlight(e.subject, s), #undefined method `truncate'
        :label => smart_truncate(e.subject, 100), #.html_safe
        :value => "#{e.id}",
        #:url => link_to_articolo(e, :title=> e.subject)  #undefined method `truncate'
        #:url => highlight_tokens(truncate(e.subject, :length => 255), s)
        #:url => '/issues/articolo/' + e.id.to_s
        :url => '/editorial/articolo/' + e.id.to_s
        }
      }
    end
    render :json => {
         :issues => @json_art,
         :total => totale,
         :page => pagina
    }
  end

#  def highlight_tokens_svc(text, tokens)
#    return text unless text && tokens && !tokens.empty?
#    re_tokens = tokens.collect { |t| Regexp.escape(t) }
#    regexp = Regexp.new "(#{re_tokens.join('|')})", Regexp::IGNORECASE
#    result = ''
#    text.split(regexp).each_with_index do |words, i|
#      if result.length > 1200
#        # maximum length of the preview reached
#        result << '...'
#        break
#      end
#      words = words.mb_chars
#      if i.even?
#        result << words.length > 100 ? "#{words.slice(0..44)} ... #{words.slice(-45..-1)}" : words
#      else
#        t = (tokens.index(words.downcase) || 0) % 4
#        result << content_tag('span', words, :class => "highlight token-#{t}")
#      end
#    end
#    result
#  end

  def zone_extend
    s =  params[:term] ? params[:term].to_s : ""
    page_limit =  params[:page_limit] ? params[:page_limit].to_i : 10
    pagina =  params[:page] ? params[:page].to_i : 1
    offset = pagina * page_limit;

    totale = Comune.find(
      :all,
      :include => [{:province => :region}],
      :conditions => ['comunes.name LIKE ? or provinces.sigla LIKE ? or provinces.name LIKE ? or regions.name LIKE ?', "%#{s}%", "%#{s}%", "%#{s}%", "%#{s}%"]
      ).count()

    @towns = Comune.find(
      :all,
      :include => [{:province => :region}],
      :conditions => ['comunes.name LIKE ? or provinces.sigla LIKE ? or provinces.name LIKE ? or regions.name LIKE ?', "%#{s}%", "%#{s}%", "%#{s}%", "%#{s}%"],
      :order => 'comunes.name',
      :limit => page_limit,
      :offset => offset
    )
    if (@towns.nil? or @towns.count < 1)
      #@json_towns = render :json => [{
      #  :id => 0,
      #  :label => "0",
      #  :value => "Nessuna città per la ricerca -#{s}-"
      #}]
      #@json_towns = [{"label":"Nessuna città per la ricerca -#{s}-","value":"","id":"0"}]
      #@json_towns = nil
      @json_towns = [{
        :id => 0,
        :label => "Nessuna città per la ricerca -#{s}-",
        :value => ""
      }]
    else
      @json_towns = @towns.collect { |e|  {
        :id =>  "#{e.id}",
        :label => "#{e.cap} #{e.name} (#{e.province.sigla}) [#{e.province.region.name}]",
        :value => "#{e.name} #{e.cap} (#{e.province.sigla})"
        }
      }
    end
    render :json => {
         :citta => @json_towns,
         :total => totale,
         :page => pagina
    }
  end

  #TypeOrganization(tipo) :: CrossOrganization(sigla) :: organizations (id <--> id e user_id)
  #Asso(ragione_sociale) :: organizations
  # User -->  	asso_id 	cross_organization_id
  def organismi
    s =  params[:term] ? params[:term].to_s : ""
    page_limit =  params[:page_limit] ? params[:page_limit].to_i : 10
    pagina =  params[:page] ? params[:page].to_i : 1
    offset = pagina * page_limit;
    totale = Organization.find(
      :all,
      :include => [:asso, {:cross_organization => :type_organization}],
      :conditions => ['type_organizations.tipo LIKE ? or cross_organizations.sigla LIKE ? or assos.ragione_sociale LIKE ?', "%#{s}%", "%#{s}%", "%#{s}%"]
      ).count()

    @FedOrgAsso = Organization.find(
      :all,
      :include => [:asso, {:cross_organization => :type_organization}],
      :conditions => ['type_organizations.tipo LIKE ? or cross_organizations.sigla LIKE ? or assos.ragione_sociale LIKE ?', "%#{s}%", "%#{s}%", "%#{s}%"],
      :order => 'type_organizations.tipo, cross_organizations.sigla, assos.ragione_sociale',
      :limit => page_limit,
      :offset => offset
    )

    if (@FedOrgAsso.nil? or @FedOrgAsso.count < 1)
      @json_datas = [{
        :id => 0,
        :label => "Nessun organismo associato per la ricerca -#{s}-",
        :value => "0",
        :hiddenvalue_cross => "0",
        :hiddenvalue_asso => "0"
      }]
    else
      @json_datas = @FedOrgAsso.collect { |e|  {
        :id => e.id,
        :value => "#{e.cross_organization.type_organization.tipo} :: #{e.cross_organization.sigla} :: " + smart_truncate("#{e.asso.ragione_sociale}", 100).html_safe,
        :label => "#{e.cross_organization.type_organization.tipo} :: #{e.cross_organization.sigla} :: " + smart_truncate("#{e.asso.ragione_sociale}", 100).html_safe,
        :hiddenvalue_cross => "#{e.cross_organization.id}",
        :hiddenvalue_asso => "#{e.id}"
        #:text => "#{e.cross_organization.type_organization.tipo}"
        }
      }
    end
    #page++
    #format.json { render :json => @detail.errors, :status => :unprocessable_entity }
    #format.json { render
    #  :json => { 'results' => @json_datas.to_json, 'total' => totale },
    #  :page => pagina
    #}
    #render :json => { :data => { :organismi => @json_datas.to_json, :total => totale }, :page => pagina.to_s }
    render :json => {
         :organismi => @json_datas, #@json_datas.to_json Kappao lato Javascript non riesce a ricostruire l'array peché è una stringa
         :total => totale,
         :page => pagina
    }
  end
#select2 rule:  Array of result objects. The default renderers expect objects with id and text keys. The id attribute is required, even if custom renderers are used.
#[{"title":"CONI","id":26},{"title":"CONI","id":29},{"title":"CONI","id":31},{"title":"CONI","id":28},{"title":"CONI","id":33},{"title":"CONI","id":30},{"title":"CONI","id":37},{"title":"CONI","id":36},{"title":"CONI","id":38}]

#  [{"title":"CONI :: PROVINCIALE :: FISCOSPORT S.R.L.","hiddenvalue_cross":"1","hiddenvalue_asso":"26","text":"CONI :: PROVINCIALE :: FISCOSPORT S.R.L."},{"title":"CONI :: PROVINCIALE :: RAG. PIETRO CANTA - Commercialista in Imperia Consulente Regionale Fiscosport Liguria Progetto \"il consulente per ...","hiddenvalue_cross":"1","hiddenvalue_asso":"29","text":"CONI :: PROVINCIALE :: RAG. PIETRO CANTA - Commercialista in Imperia Consulente Regionale Fiscosport Liguria Progetto \"il consulente per ..."},{"title":"CONI :: PROVINCIALE :: RAG. PIETRO CANTA - Commercialista in Imperia Consulente Regionale Fiscosport Liguria Progetto \"il consulente per ...","hiddenvalue_cross":"1","hiddenvalue_asso":"31","text":"CONI :: PROVINCIALE :: RAG. PIETRO CANTA - Commercialista in Imperia Consulente Regionale Fiscosport Liguria Progetto \"il consulente per ..."},{"title":"CONI :: PROVINCIALE :: STUDIO RAG. PIETRO CANTA - Commercialista in Imperia Consulente fiscale del C.P. CONI di Imperia e Consulente ...","hiddenvalue_cross":"1","hiddenvalue_asso":"28","text":"CONI :: PROVINCIALE :: STUDIO RAG. PIETRO CANTA - Commercialista in Imperia Consulente fiscale del C.P. CONI di Imperia e Consulente ..."},{"title":"CONI :: PROVINCIALE :: STUDIO RAG. PIETRO CANTA - Commercialista in Imperia Consulente Regionale Fiscosport Liguria Progetto \"il ...","hiddenvalue_cross":"1","hiddenvalue_asso":"33","text":"CONI :: PROVINCIALE :: STUDIO RAG. PIETRO CANTA - Commercialista in Imperia Consulente Regionale Fiscosport Liguria Progetto \"il ..."},{"title":"CONI :: PROVINCIALE :: STUDIO SIDERI \u0026 Associati progetto \"il consulente per le associazioni\" per la prov. di SIENA","hiddenvalue_cross":"1","hiddenvalue_asso":"30","text":"CONI :: PROVINCIALE :: STUDIO SIDERI \u0026 Associati progetto \"il consulente per le associazioni\" per la prov. di SIENA"},{"title":"CONI :: REGIONALE :: COMITATO REGIONALE FRIULI VENEZIA GIULIA Scuola Regionale dello Sport del Friuli Venezia Giulia","hiddenvalue_cross":"2","hiddenvalue_asso":"37","text":"CONI :: REGIONALE :: COMITATO REGIONALE FRIULI VENEZIA GIULIA Scuola Regionale dello Sport del Friuli Venezia Giulia"},{"title":"CONI :: REGIONALE :: CONI - Comitati Provinciali di Bolzano e Trento","hiddenvalue_cross":"2","hiddenvalue_asso":"36","text":"CONI :: REGIONALE :: CONI - Comitati Provinciali di Bolzano e Trento"},{"title":"CONI :: REGIONALE :: FISCOSPORT SRL","hiddenvalue_cross":"2","hiddenvalue_asso":"38","text":"CONI :: REGIONALE :: FISCOSPORT SRL"}]

  #TypeOrganization :: CrossOrganization :: organizations
  #Non usato perchè preferiamo una lista a discesa
  def tiposigla
    @tmp = CrossOrganization.all(:limit => 5)
    if params[:term]
      @tmp = CrossOrganization.find(
        :all,
        :joins => [:type_organization],
        :limit => 10,
        :conditions => ['sigla LIKE ? or type_organizations.tipo LIKE ?', "%#{params[:term]}%", "%#{params[:term]}%"],
        :order => 'type_organizations.tipo, sigla'
        )
    end
    if (@tmp.nil? or @tmp.count < 1)
      return render :json => [{
        :label => "0",
        :value => "Nessun organismo per -#{params[:term]}-"
      }]
    end
    @json_tmp = @tmp.collect { |e|  {:value => "#{e.type_organization.tipo} :: #{e.sigla}" , :label => "#{e.id}"} }
    render :json => @json_tmp.to_json
  end

  #Asso(ragione_sociale) :: organizations
  def assosvc
    @tmp = Asso.all(:limit => 5)
    if params[:term]
      @tmp = Asso.find(
        :all,
        :include => [:users, {:organization => {:cross_organization => :type_organization}}],
        :limit => 10,
        :conditions => ['ragione_sociale LIKE ? or users.firstname LIKE ? or users.lastname LIKE ?', "%#{params[:term]}%", "%#{params[:term]}%", "%#{params[:term]}%"],
        :order => 'ragione_sociale'
        )

#        :conditions => ['ragione_sociale LIKE ? or user.firstname LIKE ? or user.lastname LIKE ?', "%#{params[:term]}%", "%#{params[:term]}%", "%#{params[:term]}%"],
    end
    if (@tmp.nil? or @tmp.count < 1)
      return render :json => [{
        :label => "0",
        :value => "Nessuna associazione per -#{params[:term]}-"
      }]
    end
    @json_tmp = @tmp.collect { |e|  {:value => "Organismo " + smart_truncate("#{e.ragione_sociale}", 100) + " (#{e.users.count()}) #{e.organization.cross_organization.type_organization.tipo} :: #{e.organization.cross_organization.sigla}" , :label => "#{e.id}"} }
    render :json => @json_tmp.to_json
  end

end

#<% for usr in @users -%>
#  <%= usr.firstname %>, <%= usr.lastname %> | <%= usr.codice %>
#<% end -%>
#<% @users.each do |usr| %>
#  <%= usr.firstname %>, <%= usr.lastname %> | <%= usr.codice %>
#<% end %>

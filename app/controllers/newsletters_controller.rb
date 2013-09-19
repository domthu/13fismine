class NewslettersController < ApplicationController
  layout 'admin'

  before_filter :require_admin
  before_filter :find_project, :only => [ :invii, :send_newsletter ]
  before_filter :find_newsletter, :only => [ :invii, :send_newsletter, :massmailer, :send_emails, :removeemails ]
  before_filter :control_params, :only => [ :send_newsletter ]

  #before_filter :newsletter_members, :only => [ :invii ]

  verify :method => [:post, :delete], :only => [ :destroy ],
         :redirect_to => { :action => :index }

  include FeesHelper  #Domthu  FeeConst get_role_css
  helper :sort
  include SortHelper


  def invii
    if request.post?
    else
      @art = @project.issues.all_mail_fs
      if @art && @art.any?
        @newsletter.html = render_to_string(
                :layout => false,
                :partial => 'editorial/edizione_smtp',
                :locals => { :project => @project, :art => @art, :user => nil }
              )
        if ((!@newsletter.html.nil?) && (!@newsletter.html.include? "<!--checksum-->"))
          send_error("Edizione molto lungha: " + @newsletter.html.length.to_s + " caratteri. ")
        end
      end
      if @newsletter.newsletter_users.count > 0
        @last_date = @newsletter.newsletter_users.sort_by(&:updated_at).reverse.first.updated_at
        if @last_date && @newsletter.data < @last_date
          @newsletter.data = @last_date
          @newsletter.save
        end
      else
        @newsletter.data = DateTime.now
        @newsletter.save
      end
    end

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @newsletter_user }
    end
  end

  #pagina di vissualizzazione degli invi fatti per blocchi di emails
  #Questa pagina usa il layout svcmailer che include Jquery
  #Chiama via js il metodo end_emails
  def massmailer

    respond_to do |format|
      format.html {
        render :layout => 'svcmailer'
      }
    end
  end
  #via js newsletter_id:newsletterid, pageSize: pageSize
  #questa routine invia una certa quantità di emails
  def send_emails
    if @newsletter.nil?
      id = params[:newsletter_id].present? ? params[:newsletter_id].to_s : "0"
      render :json => { :errors => "Newsletter(" + id + ") da inviare non trovata", :available => true }
      return
    end
    pageSize = params[:pageSize].present? ? params[:pageSize].to_i : 100

    finish = true
    stat = ""
    @sended = []
    @failed = []
    if @newsletter.have_emails_to_send?
      if (!@newsletter.project_id.nil? && @newsletter.project)
        @art = @project.issues.all_mail_fs
        @project = @newsletter.project
        _html = render_to_string(
                  :layout => false,
                  :partial => 'editorial/edizione_smtp',
                  :locals => { :id => @project.id, :project => @project, :art => @art, :user => nil }
                )
      end

      @nl_users = @newsletter.newsletter_users.all(:limit => pageSize, :conditions => ['sended = false AND (errore is null OR LENGTH(errore) = 0)'])
      if @nl_users && @nl_users.any?
        finish = false
        raise_delivery_errors = ActionMailer::Base.raise_delivery_errors
        ActionMailer::Base.raise_delivery_errors = true
        @nl_users.each do |nl_usr|
          if nl_usr.user
            begin
              #clean clean_fs_html
               if !nl_usr.user.privato?
                @user = nl_usr.user
                conv_html = render_to_string(
                      :layout => false,
                      :partial => 'editorial/edizione_smtp_convention',
                      :locals => { :user => @user }
                    )
                _html = _html.gsub('@@user_convention@@', conv_html)
              else
                _html = _html.gsub('@@user_convention@@', '')
              end

              stat = "<a href='#{user_path(nl_usr.user)}' target='_blank'>##{nl_usr.user.name}</a> "
              @tmail =  Mailer.deliver_newsletter(nl_usr.user, _html, @newsletter.project)
              @sended << "Email inviato " + stat
              #@sended << ". Risultato => " + @tmail (can't convert TMail::Mail into String)
              nl_usr.sended = true
            rescue Exception => e
              @failed << stat + " <span style='color: red;'>" + l(:notice_email_error, e.message) + "</span>"
              nl_usr.errore = " <span style='color: red;'>" + l(:notice_email_error, e.message) + "</span>"
            end
            nl_usr.save
          else

          end
        end
        ActionMailer::Base.raise_delivery_errors = raise_delivery_errors
      end
    end
    #for i in 1..10
    #  @sended << getdatetime(Time.now) + " Sended numero <mark>#{i}</mark> "
    #  @failed << getdatetime(Time.now) + " Failed numero <mark>#{i}</mark> "
    #end

    if (@sended.any? or @failed.any?)
      return render :json => {
        :success => true,
        :sended => @sended,
        :failed => @failed,
        :msg => stat,
        :finish => finish
      }
    end
    render :json => {
        :success => true,
        :msg => stat,
        :finish => finish
    }
  end

#Params: {"conv_ids"=>["6", "13", "21", "38"], "controller"=>"newsletters", "abbo_ids"=>["7", "9", "21", "13", "19", "23", "15", "17"], "project_id"=>"342", "commit"=>"Invia quindicinale", "action"=>"send_newsletter", "newsletter_id"=>"1", "authenticity_token"=>"gFBDBOipBDj/pDGe+I9OEq5o1uq8//mcFS/JFnSkfbY="}
  #questa routine crea il job relativo ad una newsletter e crea tutti emails da mandare in funzione degli
  # ruoli o delle convenzione scelte
  def send_newsletter
    today = Date.today
    #logger.warn("edizione(" + @project.id.to_s + ") send newsletter(" + @newsletter.id.to_s + ") params #{params.inspect}")

    send_notice "Params: #{params.inspect}"
    send_it = params[:commit] == "go"
    send_warning "commit: #{params[:commit]}"
    #role
    if params[:abbo_ids].present? && !params[:abbo_ids].empty?
      (params[:abbo_ids] || []).each { |role_id|
        #send_notice "Role: #{role_id}"
        users = User.all(:conditions => {:role_id => role_id})
        if users.any?
          send_notice("Utenti(" + users.count.to_s + ") per ruolo(" + role_id + ")")
          users.each { |user|
            #crea email registration se non già presente
            yet_reg = NewsletterUser.find(:first, :conditions => ["email_type = 'newsletter' AND newsletter_id=? AND user_id=?", @newsletter.id, user.id])
            if yet_reg
              if yet_reg.sended
                send_warning("Cliente(" + user.name + ") già inviato. " + (yet_reg.errore.nil? ? "" : "ERRORE"))
              else
                send_warning("Cliente(" + user.name + ") in attesa di ricevere. " + (yet_reg.errore.nil? ? "" : "ERRORE"))
              end
            else
              reg = NewsletterUser.new(:email_type => 'newsletter', :newsletter_id => @newsletter.id, :user_id => user.id, :data_scadenza => (user.scadenza.nil? ? Date.today : user.scadenza))
              #reg.html =
              reg.sended = false
              if reg.save!  #--> save_without_transactions
                #if send immediately

                #Mailer.deliver_register(token)
              else
                send_error("invio email non registrato per utente " + user.name)
              end
            end
          }
        else
          send_error("Nessun utente di ruolo " + role_id)
        end
      }
    end
    #Convention
    if params[:conv_ids].present? && !params[:conv_ids].empty?
      (params[:conv_ids] || []).each { |conv_id|
        send_notice "=============="
        send_notice "Convenzione: #{conv_id}"
        #send_notice "Role: #{conv_id}"
        conv = Convention.find_by_id(conv_id)
        if conv && conv.users.any?
          send_notice("federati(" + conv.users.count.to_s + ") per convenzione(" + conv_id + ")")
          conv.users.each { |user|
            #crea email registration se non già presente
            yet_reg = NewsletterUser.find(:first, :conditions => ["email_type = 'newsletter' AND newsletter_id=? AND user_id=? AND convention_id=?", @newsletter.id, user.id, conv.id])
            if yet_reg
              if yet_reg.sended
                send_warning("federato(" + user.name + ") già inviato. " + (yet_reg.errore.nil? ? "" : "ERRORE"))
              else
                send_warning("federato(" + user.name + ") in attesa di ricevere. " + (yet_reg.errore.nil? ? "" : "ERRORE"))
              end
            else
              fed = NewsletterUser.new(:email_type => 'newsletter', :newsletter_id => @newsletter.id, :user_id => user.id, :data_scadenza => user.scadenza, :convention_id => conv.id)
              #reg.html =
              fed.sended = false
              if fed.save!  #--> save_without_transactions
                #if send immediately
                #Mailer.deliver_register(token)
              else
                send_error("invio email non registrato per federato " + user.name)
              end
            end
          }
        else
          send_error("Nessun federato per la convenzione " + conv_id)
        end
      }
    end

    if @newsletter.have_emails_to_send?
      redirect_to :action => 'massmailer', :newsletter_id => @newsletter.id
    else
      redirect_to :action => 'invii', :project_id => @project.id.to_s
      #redirect_to :action => 'show', :id => @newsletter
    end
  end

  # GET /newsletters
  # GET /newsletters.xml
  def index
    @newsletters = Newsletter.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @newsletters }
    end
  end

  # GET /newsletters/1
  # GET /newsletters/1.xml
  def show
    @newsletter = Newsletter.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @newsletter }
    end
  end

  # GET /newsletters/new
  # GET /newsletters/new.xml
  def new
    @newsletter = Newsletter.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @newsletter }
    end
  end

  # GET /newsletters/1/edit
  def edit
    @newsletter = Newsletter.find(params[:id])
  end

  # POST /newsletters
  # POST /newsletters.xml
  def create
    @newsletter = Newsletter.new(params[:newsletter])

    respond_to do |format|
      if @newsletter.save
        format.html { redirect_to(@newsletter, :notice => 'Newsletter was successfully created.') }
        format.xml  { render :xml => @newsletter, :status => :created, :location => @newsletter }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @newsletter.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /newsletters/1
  # PUT /newsletters/1.xml
  def update
    @newsletter = Newsletter.find(params[:id])

    respond_to do |format|
      if @newsletter.update_attributes(params[:newsletter])
        format.html { redirect_to(@newsletter, :notice => 'Newsletter was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @newsletter.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /newsletters/1
  # DELETE /newsletters/1.xml
  def destroy
    @newsletter = Newsletter.find(params[:id])
    @project_id = @newsletter.project_id
    @newsletter.destroy
    respond_to do |format|
      format.html {
        #redirect_to(newsletters_url)
        redirect_to :controller => 'projects', :action => 'show', :id => @project_id
      }
      format.xml  { head :ok }
    end
  end

  #via js delete part of NewsletterUser for resend
  def removeemails
    if params[:type].present? && !params[:type].empty?
      type = params[:type]
      if type == 'sended'
        NewsletterUser.delete_all(["email_type = 'newsletter' AND newsletter_id=? AND sended = 1", @newsletter.id])
      elsif type == 'pending'
        NewsletterUser.delete_all(["email_type = 'newsletter' AND newsletter_id=? AND sended = false AND (errore is null OR LENGTH(errore) = 0)", @newsletter.id])
      elsif type == 'errore'
        NewsletterUser.delete_all(["email_type = 'newsletter' AND newsletter_id=? AND sended = false AND errore is not null AND  LENGTH(errore) > 0", @newsletter.id])
      else

      end
    end
    render :json => { :success => true }
  end
################################
  private

    def require_fee
      if !Setting.fee
        flash[:notice] = l(:notice_setting_fee_not_allowed)
        redirect_to editorial_path
      end
    end

    def find_project
      if params[:project_id].empty?
        flash[:notice] = l(:error_can_not_create_newsletter, :project => "manca id del progetto")
        return redirect_to :controller => 'projects', :action => 'index'
      end
      #@project = Project.find(params[:project_id])
      #Questo è per il front end: la newsletter
      #@project = Project.all_public_fs.find_by_id params[:project_id].to_i
      @project = Project.all_mail_fs.find_by_id params[:project_id].to_i
      if @project.nil?
        flash[:error] = l(:error_can_not_create_newsletter, :project => "edizione non trovata")
        return redirect_to :controller => 'projects', :action => 'index'
      end
    rescue ActiveRecord::RecordNotFound
      render_404
    end

    def find_newsletter
      if params[:newsletter_id]
        @newsletter = Newsletter.find_by_id(params[:newsletter_id].to_i)
      end
      if @newsletter.nil? && @project
        @newsletter = Newsletter.find_by_project(@project.id)
      end
      if @project.nil? && @newsletter && @newsletter.project
        @project = @newsletter.project
      end
      if @newsletter.nil?

        #automatic create Newsletter
        @newsletter = Newsletter.new
        @newsletter.project_id = @project.id
        @newsletter.data = DateTime.now
        #Solo gli articoli visibile MAIL e privato: se_visible_newsletter = true
        @art = @project.issues.all_mail_fs
        if @art && @art.any?
          @newsletter.html = render_to_string(
                  :layout => false,
                  :partial => 'editorial/edizione_smtp',
                  :locals => { :id => @id, :project => @project, :art => @art, :user => nil }
                )
          if ((!@newsletter.html.nil?) && (!@newsletter.html.include? "<!--checksum-->"))
            send_error("Edizione molto lungha: " + @newsletter.html.length.to_s + " caratteri. ")
          end
          #@@user_name
          #@@user_convention
          #@@user_convention_icon
          @newsletter.sended = false
          if !@newsletter.valid?
            if !@newsletter.errors.empty?
              send_error ("Errore incontrate: " + @newsletter.errors.full_messages.join('<br />'))
            end
          end
          if !@newsletter.save
            send_error l(:error_can_not_create_newsletter, :project => @project.name)
            render_404
            #return redirect_to :controller => 'projects', :action => 'show', :id => @project
          else
            #@project.promoted_to_front_page = true
            #@project.status = STATUS_FS #raggionare su come fare: STATUS_ARCHIVED o allora creare un flag per publicazione in
            #@project.save
          end
        else
          send_warning l(:error_newsletter_mail_no_article, :project => @project.name)
          return redirect_to :controller => 'projects', :action => 'show', :id => @project
        end
      end
    end

    def control_params
      reroute_invii() unless params[:conv_ids].present? || params[:abbo_ids].present?
    end

    def reroute_invii()
      flash[:error] = "selezionare almeno un ruolo o una convenzione"
      redirect_to :action => 'invii', :project_id => @project.id.to_s
    end

end

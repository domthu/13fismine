class NewslettersController < ApplicationController
  layout 'admin'

  before_filter :require_admin
  before_filter :find_project, :only => [ :invii, :send_newsletter ]
  before_filter :find_newsletter, :only => [ :invii, :send_newsletter ]
  before_filter :control_params, :only => [ :send_newsletter ]

  #before_filter :newsletter_members, :only => [ :invii ]

  verify :method => :post, :only => [ :destroy ],
         :redirect_to => { :action => :index }

  include FeesHelper  #Domthu  FeeConst get_role_css
  helper :sort
  include SortHelper

  #gestione invii emails di una newsletter e imposti tutti utenti ad essa collegata
  # pass project_id
  #: {"role"=>{"role_id"=>"1"}, "convention"=>{"convention_id"=>""}, "project_id"=>"341", "controller"=>"newsletters", "name"=>"domthu", "action"=>"invii"}

  #Click da edizione Parameters: {"action"=>"invii", "controller"=>"newsletters", "project_id"=>"341"}
  def invii
    puts "@project id " + @project.id.to_s +  ", @newsletter id " + @newsletter.id.to_s

    #if params[:member] && request.post?
    if request.post?

    else
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

#Params: {"conv_ids"=>["6", "13", "21", "38"], "controller"=>"newsletters", "abbo_ids"=>["7", "9", "21", "13", "19", "23", "15", "17"], "project_id"=>"342", "commit"=>"Invia quindicinale", "action"=>"send_newsletter", "newsletter_id"=>"1", "authenticity_token"=>"gFBDBOipBDj/pDGe+I9OEq5o1uq8//mcFS/JFnSkfbY="}
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

    redirect_to :action => 'invii', :project_id => @project.id.to_s
    #redirect_to :action => 'show', :id => @newsletter
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
    @newsletter.destroy

    respond_to do |format|
      format.html { redirect_to(newsletters_url) }
      format.xml  { head :ok }
    end
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
        flash[:notice] = l(:error_can_not_create_newsletter, :newsletter => "manca id del progetto")
        return redirect_to :controller => 'projects', :action => 'index'
      end
      #@project = Project.find(params[:project_id])
      @project = Project.all_public_fs.find_by_id params[:project_id].to_i
      if @project.nil?
        flash[:error] = l(:error_can_not_create_newsletter, :newsletter => "edizione non trovata")
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
      if @newsletter.nil?

        #automatic create Newsletter
        @newsletter = Newsletter.new
        #@newsletter.project_id = params[:project_id].to_i
        @newsletter.project_id = @project.id
        @newsletter.data = DateTime.now
        #TODO fare una newsletter vuota
        #@newsletter.html = @project.newsletter_smtp(nil)
        #@newsletter.html = @project.newsletter_smtp(User.current)
        #@newsletter.html = "project.rb:934:in newsletter_smtp undefined method > for nil:NilClass"
        #undefined method `image_tag' for #<Project:0xb5934b0c>
        @art = @project.issues.all(:order => "#{Section.table_name}.top_section_id DESC", :include => [:section => :top_section])
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
          send_error l(:error_can_not_create_newsletter, :newsletter => @project.name)
          render_404
          #return redirect_to :controller => 'projects', :action => 'show', :id => @project
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

    def send_warning(msg)
      if flash[:warning].nil?
        flash[:warning] = msg
      else
        flash[:warning] += "<br />" + msg
      end
    end
    def send_notice(msg)
      if flash[:notice].nil?
        flash[:notice] = msg
      else
        flash[:notice] += "<br />" + msg
      end
    end
    def send_error(msg)
      if flash[:error].nil?
        flash[:error] = msg
      else
        flash[:error] += "<br />" + msg
      end
    end

end

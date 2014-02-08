class InvoicesController < ApplicationController
  layout 'admin'

  before_filter :require_admin , :except => [:fatture, :send_me_fs]
  helper :sort
  include SortHelper
  include Redmine::Export::PDF
  before_filter :set_menu
  before_filter :get_dest, :only => [:new]
  before_filter :control_dest, :only => [:create]
  before_filter :get_invoice, :only => [:show, :edit, :update, :invoice_to_pdf, :destroy, :send_customer, :send_me,  :send_me_fs]
  before_filter :retreive_dest, :only => [:show, :edit]
  before_filter :get_money, :only => [:show, :invoice_to_pdf, :send_customer, :send_me,  :send_me_fs]
  before_filter :send_invoice, :only => [:send_customer, :send_me , :send_me_fs]
  menu_item :invoices, :only => [:index]
  menu_item :invoice_receiver, :only => [:invoice_receiver]
  def set_menu
    @menu_fs = :menu_payment_fs
  end


  # GET /invoices
  # GET /invoices.xml
  def index
    #Sorting
    sort_init 'data_fattura', 'desc'
    sort_update 'numero_fattura' => 'numero_fattura',
                'user' => 'users.lastname',
                'convention' => 'conventions.ragione_sociale',
                'data_fattura' => 'data_fattura',
                'anno' => 'anno'

    @status = params[:status] ? params[:status].to_i : 1
    c = ARCondition.new(@status == 0 ? "status <> 0" : ["status = ?", @status])

    if !params[:name].blank?
      n = Integer( params[:name]) rescue nil
      if n
        c << ['id = ? ', n.to_s]
      else
        name = "%#{params[:name].strip.downcase}%"
        c << ['LOWER(login) LIKE ? OR LOWER(firstname) LIKE ? OR LOWER(lastname) LIKE ? OR LOWER(mail) LIKE ? ', name, name, name, name]
      end
      @users = User.all(:select => "DISTINCT(id)", :conditions => c.conditions)

      @invoice_count = Invoice.find(:all,:conditions => ["invoices.user_id IN (?)", @users.map(&:id)]).count
      @invoice_pages = Paginator.new self, @invoice_count, per_page_option, params['page']
      @offset ||= @invoice_pages.current.offset
      @invoices = Invoice.find :all,
                            :include => [:user, :convention ] ,
                           :order => sort_clause,
                           :conditions => ["invoices.user_id IN (?)", @users.map(&:id)],
                           :limit => @limit,
                           :offset => @offset
    else
      # Paginate results
      @invoice_count = Invoice.all.count
      @invoice_pages = Paginator.new self, @invoice_count, per_page_option * 1.5, params['page']
      @invoices = Invoice.find(:all,
                               :include => [:user, :convention],
                               :order => sort_clause,
                               :limit => @invoice_pages.items_per_page,
                               :offset => @invoice_pages.current.offset)


    end


    respond_to do |format|
      #ovverride for paging format.html # index.html.erb
      format.html {
        render :layout => !request.xhr?
      }
      format.xml { render :xml => @invoices }
    end
  end

  # GET /invoices/1
  # GET /invoices/1.xml
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.xml #{ render :xml => @invoice }
                 #format.pdf { send_data(invoice_to_pdf(@invoice), :type => 'application/pdf', :filename => @invoice.attached_invoice) }
    end

  end

  # GET /invoices/new
  # GET /invoices/new.xml
  def new
    sort_init 'id', 'id desc'
    sort_update 'id' => 'id',
                'numero_fattura' => 'numero_fattura',
                'data_fattura' => 'data_fattura',
                'anno' => 'anno'


    @invoice = Invoice.new
    item = ''
    if params[:user_id].present?
      @invoice.user_id = params[:user_id]
    end
    if params[:invoice].present? && params[:invoice][:user_id].present?
      @invoice.user_id = params[:invoice][:user_id]
    end
    if params[:convention_id].present?
      @invoice.convention_id = params[:convention_id]
    end
    if params[:invoice].present? && params[:invoice][:convention_id].present?
      @invoice.convention_id = params[:invoice][:convention_id]
    end
    @invoice.anno = Date.today.year

    #tabella riepilogo vecchie fatture fino 13 mesi prima
    start_date = Date.today  << 13
    @invoices_count = Invoice.find(:all, :conditions => ["data_fattura > ?",start_date]).count
    @invoices_pages = Paginator.new self, @invoices_count, per_page_option * 1.5 , params['page']
    @invoices =  Invoice.find(:all,
                              :conditions => ["data_fattura > ?",start_date],
                              :order => sort_clause,
                              :limit => @invoices_pages.items_per_page,
                              :offset => @invoices_pages.current.offset)


    @invoice.iva = 0.22
    @invoice.sconto = 0.00
    #sopra mette i default sotto prova a correg4gerli in base all'ultimo record
    if @invoices.count > 0
      unless @invoices[0].iva.nil?
        @invoice.iva = @invoices[0].iva
      end
#      unless @invoices[0].anno.nil?
#        @invoice.anno = @invoices[0].anno
#      end
      unless @invoices[0].tariffa.nil?
        @invoice.tariffa = @invoices[0].tariffa || 0.0
      end
      unless @invoices[0].sezione.nil?
        @invoice.sezione = @invoices[0].sezione || 'A'
      end
    end

    @cnt = Invoice.maximum(:numero_fattura, :conditions => ['anno = ' + @invoice.anno.to_s])
    if @cnt.nil? or @cnt == 0
      @cnt = 1
    else
      @cnt = @cnt + 1
    end
    @invoice.numero_fattura = @cnt.to_s
    @invoice.destinatario = @dest
    @invoice.contatto = @cont
    #@invoice.mittente = Setting.default_invoices_header
    #@invoice.description = Setting.default_invoices_description
    #@invoice.footer = Setting.default_invoices_footer

    respond_to do |format|
      format.html # new.html.erb
      format.xml { render :xml => @invoice }
    end
  end

  # GET /invoices/1/edit
  def edit
    sort_init 'id', 'id desc'
    sort_update 'id' => 'id',
                'numero_fattura' => 'numero_fattura',
                'data_fattura' => 'data_fattura',
                'anno' => 'anno'
    @invoice.anno = Date.today.year
    #tabella riepilogo vecchie fatture fino 13 mesi prima
    start_date = Date.today  << 134
    @invoices_count = Invoice.find(:all, :conditions => ["data_fattura > ?",start_date]).count
    @invoices_pages = Paginator.new self, @invoices_count, per_page_option * 1.5 , params['page']
    @invoices =  Invoice.find(:all,
                              :conditions => ["data_fattura > ?",start_date],
                              :order => sort_clause,
                              :limit => @invoices_pages.items_per_page,
                              :offset => @invoices_pages.current.offset)
  end

  # POST /invoices
  # POST /invoices.xml
  def create

    @invoice.mittente = Setting.default_invoices_header
    @invoice.description = Setting.default_invoices_description
    @invoice.footer = Setting.default_invoices_footer
    @invoice.attached_invoice = @invoice.getFileUrl

    respond_to do |format|
      if @invoice.save
        #creazione pdf
        crea_pdf_fattura
        #send email
        #format.html { redirect_to(invoice_to_pdf_path(@invoice), :notice => l(:notice_successful_create)) }
        format.html { redirect_to(@invoice, :notice => l(:notice_successful_create)) }
        #format.xml { render :xml => @invoice, :status => :created, :location => @invoice }
      else
        flash[:error] = @invoice.errors
        format.html { render :action => "new" }
        format.xml { render :xml => @invoice.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /invoices/1
  # PUT /invoices/1.xml
  def update
    respond_to do |format|
      if @invoice.update_attributes(params[:invoice])
        crea_pdf_fattura

        format.html { redirect_to(@invoice, :notice => l(:notice_successful_update)) }
       # format.xml { head :ok }
      else
       # format.html { render :action => "edit" }
        flash_now [:error] => "errore"
        format.xml { render :xml => @invoice.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /invoices/1
  # DELETE /invoices/1.xml
  def destroy
    @invoice.destroy

    respond_to do |format|
      format.html { redirect_to(invoices_url) }
      format.xml { head :ok }
    end
  end

  def invoice_receiver
    #@invid serve di rientro alla pagina modifica fatture: eventualemte per assegnare un utente alla fattura che occorre cambiare
    @invid = params[:id] || nil

    sort_init 'username', 'asc'
    sort_update 'id' => 'id',
                'username' => 'login',
                'firstname' => 'firstname',
                'lastname' => 'lastname',
                'email' => 'mail'

    case params[:format]
      when 'xml', 'json'
        @offset, @limit = api_offset_and_limit
      else
        @limit = per_page_option
    end

    scope = User
    scope = scope.in_group(params[:group_id].to_i) if params[:group_id].present?

    @status = params[:status] ? params[:status].to_i : 1
    c = ARCondition.new(@status == 0 ? "status <> 0" : ["status = ?", @status])

    unless params[:name].blank?
      n = Integer( params[:name]) rescue nil
      if n
        c << ['id = ? ', n.to_s]
      else
        name = "%#{params[:name].strip.downcase}%"
        c << ['LOWER(login) LIKE ? OR LOWER(firstname) LIKE ? OR LOWER(lastname) LIKE ? OR LOWER(mail) LIKE ? ', name, name, name, name]
      end
    end

    @user_count = scope.count(:conditions => c.conditions)
    @user_pages = Paginator.new self, @user_count, @limit, params['page']
    @offset ||= @user_pages.current.offset
    @limit = 20
    @users = scope.find :all,
                        :order => sort_clause,
                        :conditions => c.conditions,
                        :limit => @limit,
                        :offset => @offset

    @limit = 10
    @conventions_count = Convention.all.count
    @conventions_pages = Paginator.new self, @conventions_count, @limit, params['page']
    @offset2 ||= @conventions_pages.current.offset
    @conventions = Convention.find(:all,
                                   :include => [:province, :comune, :user, {:cross_organization => [:type_organization]}],
                                   :order => 'ragione_sociale',
                                   :limit => @limit,
                                   :offset => @offset2
    )
    respond_to do |format|
      format.html {

        render :layout => !request.xhr?
      }
      format.api
    end
  end

  def invoice_to_pdf
    respond_to do |format|
      format.html
      format.xml { render :xml => @invoice }
    end
  end
  def send_me_fs
    Mailer.deliver_invoice(User.current, @invoice, @body_as_string, nil, @invoice.getFilePath)
   redirect_to my_profile_show_url
    flash[:notice] = 'email inviato con pdf allegato a ' + User.current.mail
  end
  def send_me
    Mailer.deliver_invoice(User.current, @invoice, @body_as_string, nil, @invoice.getFilePath)
   #Mailer.deliver_attachments_added(attachments[:files]) if attachments.present? && attachments[:files].present? && Setting.notified_events.include?('document_added')
    redirect_to :action => 'show', :id => @invoice
    flash[:notice] = 'email inviato con pdf allegato a ' + User.current.mail
  end

  def send_customer
    user = @invoice.user
    if user.nil?
      user = @invoice.convention.user
    end
    Mailer.deliver_invoice(user, @invoice, @body_as_string, User.current, @invoice.getFilePath)
    redirect_to :action => 'show', :id => @invoice
    flash[:notice] = 'email inviato con pdf allegato al cliente ' + user.mail
  end

  def fatture

   @filename =  params[:filename]
    @filepath = "#{RAILS_ROOT}/files/invoices/" + @filename
    File.open(@filepath, 'rb') do |f|
     send_data f.read, :type => "application/pdf", :filename => @filename, :disposition => "inline"
    end
  end

  private

  def send_invoice
    @body_as_string = render_to_string(:controller => 'invoices', :action => 'invoice_to_pdf', :id => params[:id], :layout => false)
    #Controlla esistenza file
    fattura_exist?
  end

  #@invoice esiste sempre
  def crea_pdf_fattura
    get_money
    html = render_to_string(:controller => 'invoices', :action => 'invoice_to_pdf', :id => params[:id], :layout => false)
    kit = PDFKit.new(html)
    kit.to_file(@invoice.getFilePath)
    @invoice.attached_invoice = @invoice.getFileUrl
    @invoice.save!
  end

  def control_dest
    @invoice = Invoice.new(params[:invoice])
    if !@invoice.user_id.present? && !@invoice.convention_id.present?
      flash[:notice] = "Selezionare un utente o una convenzione prima di creare la fattura..."
      redirect_to(invoice_receiver_path)
    end
  end

  def get_dest
    @dest = ''
    @cont = ''
    if params[:user_id].present?
      item = User.find_by_id(params[:user_id])
      @dest += item.getDefault4invoice()
      @cont += item.getDefault4invoice_contatto()
    end
    if params[:convention_id].present?
      item = Convention.find_by_id(params[:convention_id])
      @dest += item.getDefault4invoice()
      @cont += item.getDefault4invoice_contatto()
    end
    if @dest == ''
      flash[:notice] = "Selezionare un utente o una convenzione prima di creare la fattura..."
      redirect_to(invoice_receiver_path)
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def fattura_exist?
    if !File.exist?(@invoice.getFilePath)
      crea_pdf_fattura
    end
    return File.exist?(@invoice.getFilePath)
  end

  def get_money
    @tariffa = (@invoice.tariffa || 0.00).round(2)
    @scontoperc = (@invoice.sconto || 0.00).round(2)
    @sconto = ((@tariffa * @scontoperc) / 100 || 0.00).round(2)
    @imponibile = (@tariffa - @sconto).round(2)
    @impostapercent = (@invoice.iva * 100 || 0.00).round(2)
    @impostaperc = (@invoice.iva || 0.00 ).round(2)
    @imposta = (@imponibile * @impostaperc).round(2)
    @totale = (@imponibile + @imposta ).round(2)
  end

  def get_invoice
    if !params[:id].present?
      redirect_to(invoices_path)
    end
    @invoice = Invoice.find_by_id(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def retreive_dest
    #destinatario
    if @invoice.destinatario.nil? || @invoice.destinatario.blank?
      @dest = ''
      @cont = ''
      if @invoice.user_id
        @dest += @invoice.user.getDefault4invoice()
        @cont += @invoice.user.getDefault4invoice_contatto()
      else
        if !params[:user_id].nil? && !params[:user_id].blank?
          item = User.find_by_id(params[:user_id])
          if item
            @dest += item.getDefault4invoice()
            @cont += item.getDefault4invoice_contatto()
            @invoice.user_id = item.id
          end
        end
      end

      if @invoice.convention_id
        @dest += @invoice.convention.getDefault4invoice()
        @cont += @invoice.convention.getDefault4invoice_contatto()
      else
        if !params[:convention_id].nil? && !params[:convention_id].blank?
          item = Convention.find_by_id(params[:convention_id])
          if item
            @dest += item.getDefault4invoice()
            @cont += item.getDefault4invoice_contatto()
            @invoice.convention_id = item.id
          end
        end
      end

      if @dest == ''
        flash[:notice] = "Selezionare un utente o una convenzione prima di creare la fattura..."
        redirect_to(invoice_receiver_path)
      end
      @invoice.destinatario = @dest
      @invoice.contatto = @cont
      @invoice.save

      #creazione pdf
      crea_pdf_fattura

    end
    #mittente default_invoices_header:
    if @invoice.mittente.nil? || @invoice.mittente.blank?
      @invoice.mittente = Setting.default_invoices_header
      #description default_invoices_description
      if @invoice.description.nil? || @invoice.description.blank?
        @invoice.description = Setting.default_invoices_description
      end
      #footer default_invoices_footer
      if @invoice.footer.nil? || @invoice.footer.blank?
        @invoice.footer = Setting.default_invoices_footer
      end
      @invoice.save
    end
  end

end

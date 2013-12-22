class InvoicesController < ApplicationController
  layout 'admin'

  before_filter :require_admin
  helper :sort
  include SortHelper
  include Redmine::Export::PDF
  before_filter :set_menu
  before_filter :get_dest, :only => [:new]
  before_filter :control_dest, :only => [:create]
  before_filter :get_invoice, :only => [:show, :edit, :update, :invoice_to_pdf, :destroy]
  before_filter :retreive_dest, :only => [:show, :edit]
  before_filter :get_pdf_file_path, :only => [:show, :invoice_to_pdf]
  before_filter :get_money, :only => [:show, :invoice_to_pdf]
  menu_item :invoices

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


    respond_to do |format|
      #ovverride for paging format.html # index.html.erb
      format.html {
        # Paginate results
        @invoice_count = Invoice.all.count
        @invoice_pages = Paginator.new self, @invoice_count, per_page_option, params['page']
        @invoices = Invoice.find(:all,
                                 :include => [:user, :convention],
                                 :order => sort_clause,
                                 :limit => @invoice_pages.items_per_page,
                                 :offset => @invoice_pages.current.offset)
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
    @invoices = Invoice.find(:all, :conditions => ['anno = ' + @invoice.anno.to_s], :order => 'numero_fattura DESC', :limit => 7)
    @invoice.iva = 22
    #sopra mette i default sotto prova a correggerli in base all'ultimo record
    if  @invoices.count > 0
      unless @invoices[0].iva.nil?
        @invoice.iva = @invoices[0].iva
      end
#      unless @invoices[0].anno.nil?
#        @invoice.anno = @invoices[0].anno
#      end
      unless @invoices[0].tariffa.nil?
        @invoice.tariffa = @invoices[0].tariffa
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
    @invoice.mittente = Setting.default_invoices_header
    @invoice.description = Setting.default_invoices_description
    @invoice.footer = Setting.default_invoices_footer

    respond_to do |format|
      format.html # new.html.erb
      format.xml { render :xml => @invoice }
    end
  end

  # GET /invoices/1/edit
  def edit
    #destinatario
    # if @invoice.destinatario.nil? || @invoice.destinatario.blank?
    if !params[:convention_id].nil? || !params[:user_id].nil?
      @dest = ''
      @cont = ''
      unless params[:user_id].nil?
        item = User.find_by_id(params[:user_id])
        @dest += item.getDefault4invoice()
        @cont += item.getDefault4invoice_contatto()
        @invoice.convention_id = nil
      end
      unless params[:convention_id].nil?
        item = Convention.find_by_id(params[:convention_id])
        @dest += item.getDefault4invoice()
        @cont += item.getDefault4invoice_contatto()
        @invoice.user_id = nil
      end

      @invoice.destinatario = @dest
      #end
    end
    @invoices = Invoice.find(:all,
                             :order => 'id DESC',
                             :limit => 7)
  end

  # POST /invoices
  # POST /invoices.xml
  def create
    if @invoice.sezione.blank?
      @invoice.sezione = "A"
    end


    respond_to do |format|
      if @invoice.save
        #creazione pdf
        get_pdf_file_path
        get_money
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
        format.html { redirect_to(@invoice, :notice => l(:notice_successful_update)) }
        format.xml { head :ok }
      else
        format.html { render :action => "edit" }
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
    sort_update 'username' => 'login',
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
      name = "%#{params[:name].strip.downcase}%"
      c << ["LOWER(login) LIKE ? OR LOWER(firstname) LIKE ? OR LOWER(lastname) LIKE ? OR LOWER(mail) LIKE ?", name, name, name, name]
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
    crea_pdf_fattura
    respond_to do |format|
      format.html
      format.xml { render :xml => @invoice }
    end

  end

=begin
    def invoice_download_pdf
    unless params[:id].nil?
      invoice_to_pdf()
      html = render_to_string(:controller => 'invoices', :action => 'invoice_to_pdf', :id => params[:id], :layout => false)
      pdf = PDFKit.new(html)
      pdf.stylesheets << "/public/stylesheets/pdf_in.css"
      send_data(pdf.to_pdf)
    else
      flash[:error] = 'Nessun parametro passato... errore in reservation_controller action: download_pdf '
    end
   end
=end

  private

  #@invoice esiste sempre
  def crea_pdf_fattura
    #html = render_to_string(:controller => 'invoices', :action => 'show_invoice_html', :layout => false)
    html = render_to_string(:controller => 'invoices', :action => 'invoice_to_pdf', :id => params[:id], :layout => false)
    f= RAILS_ROOT + @invoice.getInvoiceFilePath
    kit = PDFKit.new(html)
    kit.to_file(f)
    @invoice.attached_invoice = @file_pdf
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
      @cont += 'bla' # item.getDefault4invoice_contatto()
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

  def get_pdf_file_path
    @file_pdf = nil
    if File.exist?("#{RAILS_ROOT}" + @invoice.getInvoiceFilePath) and File.file?("#{RAILS_ROOT}" + @invoice.getInvoiceFilePath)
      @file_pdf = "http://" + Setting.host_name + @invoice.getInvoiceFilePath
    end
  end

  def get_money
    @tariffa = @invoice.tariffa || 0.00
    @scontoperc = @invoice.sconto || 0.00
    @sconto = (@tariffa * @scontoperc) / 100
    @imponibile = @tariffa - @sconto
    @impostapercent = @invoice.iva * 100 || 0.00
    @impostaperc = @invoice.iva || 0.00
    @imposta = (@imponibile * @impostaperc)
    @totale = @imponibile + @imposta
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
    if (@invoice.destinatario.nil? || @invoice.destinatario.blank?) || (!@invoice.user_id.nil? && !@invoice.convention_id.nil?) || (@invoice.user_id.nil? && @invoice.convention_id.nil?)
#    if @invoice.destinatario.nil? || @invoice.destinatario.blank? || }"
      @dest = ''
      @cont = ''
      unless @invoice.user_id.nil? || @invoice.user_id.blank?
        item = User.find_by_id(params[:user_id])
        if item
          @dest += item.getDefault4invoice()
          @cont += item.getDefault4invoice_contatto()
          @invoice.convention_id = nil
        else
          @invoice.user_id = nil
        end
      end
      unless @invoice.convention_id.nil? || @invoice.convention_id.blank?
        item = Convention.find_by_id(params[:convention_id])
        if item
          @dest += item.getDefault4invoice()
          @cont += item.getDefault4invoice_contatto()
          @invoice.user_id = nil
        else
          @invoice.convention_id = nil
        end

      end
      if @dest == ''
        flash[:notice] = "Selezionare un utente o una convenzione prima di creare la fattura..."
        redirect_to(invoice_receiver_path)
      end
      #mittente default_invoices_header:
      if @invoice.mittente.nil? || @invoice.mittente.blank?
        @invoice.mittente = Setting.default_invoices_header
      end
      #description default_invoices_description
      if @invoice.description.nil? || @invoice.description.blank?
        @invoice.description = Setting.default_invoices_description
      end
      #footer default_invoices_footer

      if @invoice.footer.nil? || @invoice.footer.blank?
        @invoice.footer = Setting.default_invoices_footer
      end
      @invoice.destinatario = @dest
      @invoice.contatto = @cont

      @invoice.save
    end
  end

end

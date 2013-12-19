class InvoicesController < ApplicationController
  layout 'admin'

  before_filter :require_admin
  helper :sort
  include SortHelper
  include Redmine::Export::PDF
  before_filter :set_menu
  before_filter :get_dest, :only => [:new]
  before_filter :retreive_dest, :only => [:show , :edit]
  menu_item :invoice, :only => [:index]
  menu_item :invoices, :only => [:invoices]
  menu_item :email_fee, :only => [:email_fee]
  menu_item :invia_fatture, :only => [:invia_fatture]


  def set_menu
    case self.action_name
      when 'index', 'show', 'edit', 'invoice_receiver','invoice_to_pdf' ,'download_pdf'
        @menu_fs = :menu_payment_fs
      else
        @menu_fs = :application_menu
    end
  end

  def invoice_receiver
    #serve eventualemte per assegnare un utente alla fattura che non ne ha
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
    @limit = 10
    @users = scope.find :all,
                        :order => sort_clause,
                        :conditions => c.conditions,
                        :limit => @limit,
                        :offset => @offset

    @limit = 8
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
    @invoice = Invoice.find(params[:id])
    @tariffa = @invoice.tariffa || 0
    @scontoperc = @invoice.sconto || 0
    @sconto = (@tariffa * @scontoperc) / 100
    @imponibile = @tariffa - @sconto
    @impostaperc = @invoice.iva || 0
    @imposta = (@imponibile * @impostaperc) / 100
    @totale = @imponibile + @imposta
  end

  def invoice_download_pdf
    unless params[:id].nil?
      html = render_to_string(:controller => 'invoices', :action => 'invoice_to_pdf', :id => params[:id], :layout => false)
      pdf = PDFKit.new(html)
      send_data(pdf.to_pdf)
    else
      flash[:error] = 'Nessuna fattura passata come parametro. '
    end
  end

  # GET /invoices
  # GET /invoices.xml
  def index
    #@invoices = Invoice.all
    #respond_to do |format|
    #  format.html # index.html.erb
    #  format.xml  { render :xml => @invoices }
    #end

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
                                 :include => [:user , :convention],
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
    @invoice = Invoice.find(params[:id])
    @tariffa =  @invoice.tariffa || 0.00
    @scontoperc = @invoice.sconto || 0.00
    @sconto = (@tariffa * @scontoperc) / 100
    @imponibile = @tariffa - @sconto
    @impostapercent = @invoice.iva * 100 || 0.00
    @impostaperc = @invoice.iva  || 0.00
    @imposta = (@imponibile * @impostaperc) / 100
    @totale = @imponibile + @imposta
    respond_to do |format|
      format.html # show.html.erb
      format.xml { render :xml => @invoice }
      # format.pdf { send_data(invoice_to_pdf(@invoice), :type => 'application/pdf', :filename => 'export.pdf') }
    end

  end

  # GET /invoices/new
  # GET /invoices/new.xml
  def new
    item = ''
    @pu = params[:user_id].present?
    @pc = params[:convention_id].present?
    @invoice = Invoice.new
    @invoice.iva = 22
    @invoice.anno = Date.today.year
    @invoices = Invoice.find(:all,
                             :order => 'id DESC',
                             :limit => 7)
    @cnt = Invoice.maximum(:numero_fattura, :conditions => ['anno = ' + @anno.to_s])
    if @cnt.nil? or @cnt == 0
      @cnt = 1

    else
      cnt += 1
    end
    @invoice.numero_fattura = cnt
    @invoice.destinatario = @dest
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
    @invoice = Invoice.find(params[:id])
    #destinatario
   # if @invoice.destinatario.nil? || @invoice.destinatario.blank?
   if !params[:convention_id].nil? ||  !params[:user_id].nil?
      @dest = ''
      unless params[:user_id].nil?
        item = User.find_by_id(params[:user_id])
        @dest += item.getDefault4invoice()
        @invoice.convention_id = nil
      end
      unless params[:convention_id].nil?
        item = Convention.find_by_id(params[:convention_id])
        @dest += item.getDefault4invoice()
        @invoice.user_id = nil
      end

      @invoice.destinatario = @dest
   #end
     end
=begin
      if (@dest == '') && (@invoice.convention_id.nil? && @invoice.user_id.nil?)
        flash[:notice] = "Selezionare un utente o una convenzione prima di creare la fattura..."
        redirect_to(invoice_receiver_path)
      else
        #mittente default_invoices_header:
        if @invoice.mittente.nil? || @invoice.mittente.blank?
          @invoice.mittente = Setting.default_invoices_header
        end
        #description default_invoices_description
        if @invoice.description.nil? || @invoice.description.blank?
          @invoice.description = Setting.default_invoices_description
        end
        #footer default_invoices_footer
        @invoice.footer = Setting.default_invoices_footer
        @invoice.destinatario = @dest
      end
=end
    @invoices = Invoice.find(:all,
                             :order => 'id DESC',
                             :limit => 7)
  end

  # POST /invoices
  # POST /invoices.xml
  def create
    @invoice = Invoice.new(params[:invoice])

    respond_to do |format|
      if @invoice.save
        format.html { redirect_to(@invoice, :notice => l(:notice_successful_create)) }
        format.xml { render :xml => @invoice, :status => :created, :location => @invoice }
      else
        format.html { render :action => "new" }
        format.xml { render :xml => @invoice.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /invoices/1
  # PUT /invoices/1.xml
  def update
    @invoice = Invoice.find(params[:id])

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
    @invoice = Invoice.find(params[:id])
    @invoice.destroy

    respond_to do |format|
      format.html { redirect_to(invoices_url) }
      format.xml { head :ok }
    end
  end


  private

  def get_dest
    @dest = ''
    if params[:user_id].present?
      item = User.find_by_id(params[:user_id])
      @dest += item.getDefault4invoice()
    end
    if params[:convention_id].present?
      item = Convention.find_by_id(params[:convention_id])
      @dest += item.getDefault4invoice()
    end
    if @dest == ''
      flash[:notice] = "Selezionare un utente o una convenzione prima di creare la fattura..."
      redirect_to(invoice_receiver_path)
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end


  def retreive_dest
    @invoice = Invoice.find(params[:id])
    #destinatario
    if (@invoice.destinatario.nil? || @invoice.destinatario.blank?) || (!@invoice.user_id.nil? && !@invoice.convention_id.nil?) || (@invoice.user_id.nil? && @invoice.convention_id.nil?)
#    if @invoice.destinatario.nil? || @invoice.destinatario.blank? || }"
      @dest = ''
      unless @invoice.user_id.nil? || @invoice.user_id.blank?
        item = User.find_by_id(params[:user_id])
        if item
        @dest += item.getDefault4invoice()
        @invoice.convention_id = nil
        else
          @invoice.user_id = nil
          end
        end
      unless @invoice.convention_id.nil? || @invoice.convention_id.blank?
        item = Convention.find_by_id(params[:convention_id])
        if item
        @dest += item.getDefault4invoice()
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
        @invoice.destinatario =  @dest

        @invoice.save
      end
  #  @invoice.destinatario = '>>>>>>' +  (!@invoice.user_id.nil? && !@invoice.convention_id.nil?).to_s
     #  @invoice.update_attributes(params[:user_id,:convention_id,:mittente,:destinatario,:description,:footer ])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end

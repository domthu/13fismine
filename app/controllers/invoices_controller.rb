class InvoicesController < ApplicationController
  layout 'admin'

  before_filter :require_admin

  helper :sort
  include SortHelper

  include Redmine::Export::PDF

  # GET /invoices
  # GET /invoices.xml
  def index
    #@invoices = Invoice.all
    #respond_to do |format|
    #  format.html # index.html.erb
    #  format.xml  { render :xml => @invoices }
    #end

    #Sorting
    sort_init 'numero_fattura', 'desc'
    sort_update 'numero_fattura' => 'numero_fattura',
                'user' => 'user',
                'data_fattura' => 'data_fattura',
                'anno' => 'anno',
                'tariffa' => 'tariffa',
                'pagamento' => 'pagamento'

    respond_to do |format|
      #ovverride for paging format.html # index.html.erb
      format.html {
        # Paginate results
        @invoice_count = Invoice.all.count
        @invoice_pages = Paginator.new self, @invoice_count, per_page_option, params['page']
        @invoices = Invoice.find(:all,
                          :order => sort_clause,
                          :limit  =>  @invoice_pages.items_per_page,
                          :offset =>  @invoice_pages.current.offset)
        render :layout => !request.xhr?
      }
      format.xml  { render :xml => @invoices }
    end
  end

  # GET /invoices/1
  # GET /invoices/1.xml
  def show
    @invoice = Invoice.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @invoice }
      format.pdf  { send_data(invoice_to_pdf(@invoice), :type => 'application/pdf', :filename => 'export.pdf') }
    end

  end

  # GET /invoices/new
  # GET /invoices/new.xml
  def new
    @invoice = Invoice.new
    @anno = Date.today.year
    #@cnt = Invoice.count(:conditions => ['anno = ' + @anno.to_s ])
    @cnt = Invoice.maximum(:numero_fattura, :conditions => ['anno = ' + @anno.to_s ])
    if @cnt.nil? or @cnt == 0
      @cnt = 1
    else
       @cnt += 1
    end

#Person.minimum(:age, :conditions => ['last_name != ?', 'Drake']) # Selects the minimum age for everyone with a last name other than 'Drake'
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @invoice }
    end
  end

  # GET /invoices/1/edit
  def edit
    @invoice = Invoice.find(params[:id])
  end

  # POST /invoices
  # POST /invoices.xml
  def create
    @invoice = Invoice.new(params[:invoice])

    respond_to do |format|
      if @invoice.save
        format.html { redirect_to(@invoice, :notice => l(:notice_successful_create)) }
        format.xml  { render :xml => @invoice, :status => :created, :location => @invoice }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @invoice.errors, :status => :unprocessable_entity }
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
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @invoice.errors, :status => :unprocessable_entity }
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
      format.xml  { head :ok }
    end
  end

end

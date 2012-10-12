class ContractUsersController < ApplicationController
  # GET /contract_users
  # GET /contract_users.xml
  def index
    @contract_users = ContractUser.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @contract_users }
    end
  end

  # GET /contract_users/1
  # GET /contract_users/1.xml
  def show
    @contract_user = ContractUser.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @contract_user }
    end
  end

  # GET /contract_users/new
  # GET /contract_users/new.xml
  def new
    @contract_user = ContractUser.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @contract_user }
    end
  end

  # GET /contract_users/1/edit
  def edit
    @contract_user = ContractUser.find(params[:id])
  end

  # POST /contract_users
  # POST /contract_users.xml
  def create
    @contract_user = ContractUser.new(params[:contract_user])

    respond_to do |format|
      if @contract_user.save
        format.html { redirect_to(@contract_user, :notice => 'ContractUser was successfully created.') }
        format.xml  { render :xml => @contract_user, :status => :created, :location => @contract_user }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @contract_user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /contract_users/1
  # PUT /contract_users/1.xml
  def update
    @contract_user = ContractUser.find(params[:id])

    respond_to do |format|
      if @contract_user.update_attributes(params[:contract_user])
        format.html { redirect_to(@contract_user, :notice => 'ContractUser was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @contract_user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /contract_users/1
  # DELETE /contract_users/1.xml
  def destroy
    @contract_user = ContractUser.find(params[:id])
    @contract_user.destroy

    respond_to do |format|
      format.html { redirect_to(contract_users_url) }
      format.xml  { head :ok }
    end
  end
end

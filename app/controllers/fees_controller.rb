class FeesController < ApplicationController

  layout 'admin'

  before_filter :require_admin, :require_fee

  helper :sort
  include SortHelper

  def index
  
  end

###########LISTE UTENTI PER RUOLO##############
  def registrati
  end

  def scaduti
  end

  def archiviati
  end

  def paganti
  end

  def abbonamenti
    @username = params[:user] ? params[:user].to_i : ''
    @users = User.find_by_api_key(username)
    @role = params[:role] ? params[:role].to_i : 1
    @users_role = User.all(:conditions => {:role_id => @role}, :include => :role)
#    :conditions => "parent_id IS NULL AND status = #{Project::STATUS_ACTIVE}",
  end

  def privati
  end

  def associati
  end

##########GESTIONE PAGAMENTI ABBONAMENTO
  def pagamento
  end

  def invia_fatture
  end

  #Mailer.Deliver_fee  
  #in models/def fee(user, type, setting_text)
  #add route /fees/email_fee
  def email_fee
    #proposal
    #thanks
    #asso
    #renew
    @type = params[:type]
    return redirect_to :controller => 'settings', :action => 'edit', :tab => 'general'
    raise_delivery_errors = ActionMailer::Base.raise_delivery_errors
    # Force ActionMailer to raise delivery errors so we can catch it
    ActionMailer::Base.raise_delivery_errors = true
    begin
      #lib/tasks/email.rake
      #app/models/mailer.rb  -> def fee(user, type, setting_text)   fee e fee_url
      #app/invoice/views/_fee.text.erb
      #app/invoice/views/_fee.html.erb
      if @type == 'proposal'
        @test = Mailer.deliver_fee(User.current, @type, Setting.template_fee_proposal)
      elsif @type == 'thanks'
        @test = Mailer.deliver_fee(User.current, @type, Setting.template_fee_thanks)
      elsif @type == 'asso'
        @test = Mailer.deliver_fee(User.current, @type, Setting.template_fee_register_asso)
      elsif @type == 'renew'
        @test = Mailer.deliver_fee(User.current, @type, Setting.template_fee_renew)
      end
      flash[:notice] = l(:notice_email_sent, User.current.mail)
    rescue Exception => e
      flash[:error] = l(:notice_email_error, e.message)
    end
    ActionMailer::Base.raise_delivery_errors = raise_delivery_errors
    redirect_to :controller => 'settings', :action => 'edit', :tab => 'fee'
  end
  
end
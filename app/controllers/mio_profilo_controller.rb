# Redmine - project management software
# Copyright (C) 2006-2011  Created by  DomThual & SPecchiaSoft (2013)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

class MioProfiloController < ApplicationController
  before_filter :require_login
  layout 'editorial'
  helper :issues
  helper :users
  include FeesHelper

  # Show user's page account
  def page
    @user = User.current
  end

  # Edit user's page account
#  Parameters: {"user"=>{"comune_id"=>"628", "titolo"=>"Impiegata", "mail"=>"loredana@studiomurizzascodompe.fr", "se_condition"=>"1", "soc"=>"MURIZZASCO LOREDANA", "login"=>"loredana", "id"=>"159", "se_privacy"=>"1", "partitaiva"=>"00754900041", "telefono"=>"0174330887-", "codicefiscale"=>"MRZLDN51T63F351R", "lastname"=>"LOREDANA2", "firstname"=>"MURIZZASCO2", "codice_attivazione"=>"", "language"=>"en", "cross_organization_id"=>"", "fax"=>"32616771", "indirizzo"=>"Via xx settembre 30"}, "authenticity_token"=>"Lm7zBhhiwUqXRxoiiXm94Y5wrWbxC6QwzyAE263VRWk=", "controller"=>"mio_profilo", "commit"=>"Invia", "action"=>"account", "extra_town"=>""}
  def account
    @user = User.current
    #@pref = @user.pref
    if request.post?
      old_login = @user.login
      @user.safe_attributes = params[:user]
      @user.pref.attributes = params[:pref]
      @user.pref[:no_self_notified] = (params[:no_self_notified] == '1')
      if params[:user][:login].present? && !params[:user][:login].blank? && params[:user][:login] != old_login
        @user.login = params[:user][:login][0,30]
        old_login = "cambiato"
      end
      if @user.save
        @user.pref.save
        @user.notified_project_ids = (@user.mail_notification == 'selected' ? params[:notified_project_ids] : [])
        set_language_if_valid @user.language
        flash[:notice] = l(:notice_account_updated)
        if (old_login == "cambiato")
          Mailer.deliver_account_information(@user, @user.pwd)
        end
        redirect_to :action => 'page'
        return
      end
    end
  end

  # Manage user's password
  def password
    @user = User.current
    unless @user.change_password_allowed?
      flash[:error] = l(:notice_can_t_change_password)
      redirect_to :action => 'account'
      return
    end
    if request.post?
      if @user.check_password?(params[:password])
        @user.password, @user.password_confirmation = params[:new_password], params[:new_password_confirmation]
        if @user.save
          flash[:notice] = l(:notice_account_password_updated)
          redirect_to :action => 'account'
        end
      else
        flash[:error] = l(:notice_account_wrong_password)
      end
    end
  end

end

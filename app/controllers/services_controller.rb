class ServicesController < ApplicationController

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
    Rails.logger.info("json emailctrl")
    if params[:term] && params[:field]
      Rails.logger.info("json emailctrl #{params[:term]} per field #{params[:field]}")
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
end

#<% for usr in @users -%>
#  <%= usr.firstname %>, <%= usr.lastname %> | <%= usr.codice %>
#<% end -%>
#<% @users.each do |usr| %>
#  <%= usr.firstname %>, <%= usr.lastname %> | <%= usr.codice %>
#<% end %>

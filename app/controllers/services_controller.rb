class ServicesController < ApplicationController

#http://andrewcox.org/post/507032751/rails-3-0-unobtrusive-ajax-in-rails-2-3-x
  #http://rwldesign.com/journals/1-solutions/posts/32-using-jquery-ui-autocomplete-with-rails
  def Usertitle
    Rails.logger.info("json Usertitle")
    @users = User.all(:limit => 5)
    if params[:term]
      Rails.logger.info("json Usertitle #{params[:term]}")
      #sanitize string for only
      #, :distinct => 'titolo'    ArgumentError --> Unknown key(s): distinct
      @users = User.find(:all, :limit => 5, :conditions => ['titolo LIKE ?', "%#{params[:term]}%"])

#      @user = User.search params[:term],
#          :limit => 5,
#          :match_mode => :any,
#          :field_weights => { :name => 20, :description => 10, :reviews_content => 5 }
    end

    if (@users.nil? or @users.count < 1)
      #@users = User.find(:all, :limit => 5)
      @users = User.all(:limit => 5)
    end

    #Rails.logger.info("json Usertitle (%s)" % @users)
    #printf 'users =========> %s', @users
    Rails.logger.debug('users =========> ')

    respond_to do |format|
      #format.html # index.html.erb
      #format.xml  { render :xml => @users }
      format.js{
        render :text => "alert('hello')"
      } # usertitle.js.erb
      format.json { render :json => @users, :layout => false }
      #format.json { render :json => @users.to_json }
    end
  end

end

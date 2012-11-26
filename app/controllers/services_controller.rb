class ServicesController < ApplicationController

  #http://rwldesign.com/journals/1-solutions/posts/32-using-jquery-ui-autocomplete-with-rails
  def Usertitle
    Rails.logger.info("json Usertitle")
    if params[:term]
      Rails.logger.info("json Usertitle #{params[:term]}")
      #sanitize string for only
      @user = User.find(:all, :limit => 5, :distinct => 'titolo', :conditions => ['titolo LIKE ?', "%#{params[:term]}%"])

#      @user = User.search params[:term],
#          :limit => 5,
#          :match_mode => :any,
#          :field_weights => { :name => 20, :description => 10, :reviews_content => 5 }
    else
      #@user = User.all
      @user = User.find(:all, :limit => 5, :distinct => 'titolo')
    end

    respond_to do |format|
      format.js
      #format.json { render :json => @user.to_json }
      end
  end

end

require "#{RAILS_ROOT}/app/helpers/conventions_helper"
include ConventionsHelper

#Attenzione installare la $ gem install hapricot
require 'diff'
require File.expand_path(File.dirname(__FILE__) + "/../undress/textile")

namespace :db do
  n=3390
  desc "Parse HTML to Wiki format using ?"
  task :html_to_textile => :environment do

  #{RAILS_ROOT}/lib/undress errors WHERE CO_IDContenuto= 1728"
    ActiveRecord::Base.connection.execute("SELECT CO_IDContenuto, CO_Testo FROM `xcontenuti_textile`
            WHERE (CO_IDContenuto <> 1728 AND CO_IDContenuto <> 2177 AND CO_IDContenuto <> 2856 AND CO_IDContenuto <> 3041 AND CO_IDContenuto <> 3041 AND CO_IDContenuto <> 3047 AND CO_IDContenuto <> 3096 AND CO_IDContenuto <> 3390)
              LIMIT 3390, 3800").each() do |art|

     puts " [rec: " + n.to_s + " ]"
     n += 1
      @text = art[1]
       if !@text
         @text = "-"
       end
      @ind = @text.index(' risposta a cura')
      if @ind
        puts @text.to_s + " <---------------- è un quesito ???????????????????\n"
          @text = @text[@ind .. -1]
      end
      @articolo_id = art[0].to_i
     # puts smart_truncate2( "[" + @articolo_id.to_s + "]" + @text, 100)
   #   puts "\n..........................................\n"

	    #@issue = Issue.find_by_id(15);
      @issue = Issue.find_by_id(@articolo_id)
      if @issue.nil?
	      puts @articolo_id.to_s + " ????????????????????????????????????\n"
	    #  puts "p-(" + art[0].to_s + ") a-(" + art[1].to_s + ") => " + smart_truncate2(@text, 100)
	     # puts "??????????????????????????????????????????????????????????????\n"
	    else
	      @issue.description = Undress(@text).to_textile
	      puts smart_truncate2(@issue.description, 100)
	      @issue.save()
        puts @articolo_id.to_s + " !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n"
      end
      # puts "\n\n*****************************************************\n\n"
	  end


  end
end

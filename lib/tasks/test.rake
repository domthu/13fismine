require "#{RAILS_ROOT}/app/helpers/assos_helper"
include AssosHelper

#Attenzione installare la $ gem install hapricot
require 'diff'
require File.expand_path(File.dirname(__FILE__) + "/../undress/textile")

namespace :db do
  desc "Parse HTML to Wiki format using ?"
  task :testami => :environment do

    puts '#{RAILS_ROOT}/lib/undress'
   # ActiveRecord::Base.connection.execute("SELECT CO_IDContenuto, CO_Testo FROM `xcontenuti_textile` LIMIT 0 , 30").each() do |art|

      @text = "<h1>Questa è una provola</h1> indice questo è il <b>seguito</b> "
    @ind = @text.index('questo indice')
     # @articolo_id = art[0].to_i
     # puts smart_truncate2( "[" + @articolo_id.to_s + "]" + @text, 100)
      puts "\n.........................................."  + @ind.to_s

	    #@issue = Issue.find_by_id(15);
    #  @issue = Issue.find_by_id(@articolo_id);
	    if @ind.nil?
	      puts "nill ??????????????????????????????????????????????????????????????\n"
      else
       @text = @text[@ind .. -1]

	      puts Undress(@text).to_textile

      end
      puts "\n\n*****************************************************\n\n"
	  #end


  end
end
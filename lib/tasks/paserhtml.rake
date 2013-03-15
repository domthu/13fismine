require "#{RAILS_ROOT}/app/helpers/assos_helper"
include AssosHelper

#Attenzione installare la $ gem install hapricot
require 'diff'
require File.expand_path(File.dirname(__FILE__) + "/../undress/textile")

namespace :db do
  desc "Parse HTML to Wiki format using ?"
  task :parsehtml => :environment do

    puts '#{RAILS_ROOT}/lib/undress'
    ActiveRecord::Base.connection.execute("SELECT CO_IDContenuto, CO_Progressivo, CO_Testo FROM xcontenuti LIMIT 0 , 30").each() do |art|

      @text = art[2]
      @articolo_id = art[0].to_i
      puts smart_truncate2( "[" + @articolo_id.to_s + "]" +@text, 100)
      puts "\n..........................................\n"

	    #@issue = Issue.find_by_id(15);
      @issue = Issue.find_by_id(@articolo_id);
	    if @issue.nil?
	      puts "??????????????????????????????????????????????????????????????\n"
	      puts "p-(" + art[0].to_s + ") a-(" + art[1].to_s + ") => " + smart_truncate2(@text, 100)
	      puts "??????????????????????????????????????????????????????????????\n"
	    else
	      @issue.description = Undress(@text).to_textile
	      puts smart_truncate2(@issue.description, 100)
	      @issue.save()
      end
      puts "\n\n*****************************************************\n\n"
	  end


  end
end	

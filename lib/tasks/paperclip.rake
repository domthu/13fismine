#require "#{RAILS_ROOT}/app/helpers/conventions_helper"
#include ConventionsHelper
#Attenzione installare la $ gem install hapricot
#require 'diff'
#require File.expand_path(File.dirname(__FILE__) + "/../undress/textile")

#we use this to get the image.
#require 'rest-open-uri'

namespace :migrate do
  desc "reccupera le vecchie imagine del sito e caricale dentro i campi paperclip"
  task :load_old_image => :environment do

    i=0
    no=0
    ye=0

    require 'rubygems'
    require 'open-uri'
    require 'net/http'
    require 'paperclip'

    puts "\n..........................................\n"
    #existing_issues = Issue.all()
    existing_issues = Issue.all(:conditions=>["immagine_url is not null"])
    for art in existing_issues do
      begin
        i += 1
        if (art.immagine_url && !art.immagine_url.nil?)
          url = 'http://www.fiscosport.it/allegati/' + art.immagine_url

          ye += 1
          puts "[rec: " + i.to_s + "/" + ye.to_s + "/" + no.to_s + "] --> " + art.immagine_url
          #art.image = File.open("...")
          #art.image = open(url)  #require 'rest-open-uri'

          io = open(URI.escape(url))

          if io
            def io.original_filename; base_uri.path.split('/').last; end
            io.original_filename.blank? ? nil : io
            puts "; io.original_filename('" + io.original_filename + "')"
            art.image = io
          end
          #art.save!
          #art.save()
          art.save(false)
        else
          no += 1
          #puts "[rec: " + i.to_s + "/" + ye.to_s + "/" + no.to_s + "] Kappao "
        end
        puts "!!" + art.id.to_s + "!!!!!\n"

      rescue Exception => e
        puts "\nEXCEPTION# #{e.message}\n"
      end
    end
    puts "\n..........................................\n"
    #[rec: 1955/704/1251]
  end
end

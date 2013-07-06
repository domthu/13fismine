#require "#{RAILS_ROOT}/app/helpers/conventions_helper"
#include ConventionsHelper
#Attenzione installare la $ gem install hapricot
#require 'diff'
#require File.expand_path(File.dirname(__FILE__) + "/../undress/textile")

#we use this to get the image.
#require 'rest-open-uri'

namespace :migrate do
  desc "rigenera tutte le immagine delle varie tabele che usanno i campi paperclip"
  task :Load_old_members => :environment do

    i=0
    no=0
    ye=0

    require 'rubygems'
    require 'open-uri'
    require 'net/http'
    require 'paperclip'

    puts "\n..........................................\n"

    @managers = User.all(:conditions => {:role_id => FeeConst::ROLE_MANAGER, :admin => false })
    @authors = User.all(:conditions => {:role_id => FeeConst::ROLE_AUTHOR, :admin => false})
    existing_projects = Projects.all(:conditions=>["photo_file_name is not null"])
    for prj in existing_projects do
      begin
        i += 1
        if prj.members.nil? || prj.members.count <= 0
          ye += 1
          puts "[members: " + i.to_s + "/" + ye.to_s + "/" + no.to_s + "] --> " + prj.name
          prj.members_fs_add_author_manager(@managers, @authors)
        else
          no += 1
          puts "[rec: " + i.to_s + "/" + ye.to_s + "/" + no.to_s + "] Kappao "
        end
      end
    end
    puts "\n..........................................\n"
    #[rec: 1955/704/1251]

  end
end

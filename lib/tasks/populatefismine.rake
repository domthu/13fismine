#require 'faker'

namespace :db do
  desc "Fill database with some fundamental data"
  task :populatefismine => :environment do
    
#    Rake::Task['db:reset'].invoke  questo azzero tutto il db

#require 'faker'
    #99.times do |n|
    #  name  = Faker::Name.name
    #  email = "example-#{n+1}@railstutorial.org"
    #  password  = "a"
    #  User.create!(:name => name,
    #               :email => email,
    #               :password => password,
    #               :password_confirmation => password)
    #end

#Esempi
    #Country.create!(:code => "IT", :name => "Italy")
    #Country.create!(:code => "UK", :name => "United Kingdom")
    #User.create!(:name => "partner2", :email => "paul.hayes@port.ac.uk",
    #         :password => "p2", :password_confirmation => "p2", :Number => 1)
    #User.create!(:name => "partner3", :email => "medlin@obs-banyuls.fr",
    #         :password => "p3", :password_confirmation => "p3", :Number => 1)
    #CodeType.create!(:code => "B", :name => "Organism bacteria", :partner_id => 5)
    #CodeType.create!(:code => "L", :name => "Water type Lake", :partner_id => 4)
    #Geo.create!(:name => "Canet Saint Nazaire lagoon", :lon => 3.029523, :lat => 42.659567, :country_id => 3 )
    #Geo.create!(:name => "SOLA station", :lon => 3.029523 , :lat => 42.659567, :country_id => 3 )

#Caricare da un file con dati separati da ':'
#    file = File.open('lib/tasks/data/edizioni.sql', 'r')
#    file.each do |line|
#    #file.each_line("\n") do |line|
#      attrs = line.split(":")
#      p = Project.find_or_initialize_by_id(attrs[0])
#      p.name = attrs[1]
#      etc...
#      p.save!
#    end

#le tabelle da integrare devono essere fatte in questo ordine

  end
end


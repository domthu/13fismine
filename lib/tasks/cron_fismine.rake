
namespace :db do
  desc "Motore notturno di fismine"
  task :cron_fismine => :environment do
    msg=""
    i=0
    no=0
    ye=0
    puts "\n..........................................\n"
#========================= controlla i ruoli per convenzione
#user = User.new
#user.role_id = FeeConst::ROLE_REGISTERED
#user.name = "user name"
#user.save!
#--> get user.id

#========================= controlla i paganti

#========================= Archivia i dati vecchi di newsletter_id
  #Comune.destroy_all  110 province 8 092 comuni
  #ActiveRecord::Base.connection.execute('ALTER TABLE comunes AUTO_INCREMENT = 1')
  #Comune.create!(:id => 3319, :name => "CISLIANO", :region_id => 97, :province_id => 19)

  #newsletter_archive.created_at = newsletter_user.updated_at


#========================= inviare le email se ci sono in newsletter_id

#========================= pulire i file di log (inviare via email)

    puts "[rec: " + i.to_s + "/" + ye.to_s + "/" + no.to_s + "] "
    puts "\n..........................................\n"

#========================= sendemail se msg not empty
  end
end

namespace :db do
  desc "Imposta ruoli Fiscosport come non cancellabile"
  task :fisminebuiltin => :environment do

    puts "Impostazione builtin su tabella Role"

    #3 	Manager
    Role.update!( :id => 3, :builtin => 3)
    #undefined method `update!' for #<Class:0xb63d4774>
    #4 	Redattore
    #6 	Abbonato
    #7 	Scaduti
    #8 	Archiviati
    #9 	Ospite
    #10 	Gratuito
    #11 	Rinnovo

  end
end

#UPDATE roles SET builtin = 3 WHERE id = 3;
#UPDATE roles SET builtin = 4 WHERE id = 4;
#UPDATE roles SET builtin = 6 WHERE id = 6;
#UPDATE roles SET builtin = 7 WHERE id = 7;
#UPDATE roles SET builtin = 8 WHERE id = 8;
#UPDATE roles SET builtin = 9 WHERE id = 9;
#UPDATE roles SET builtin = 10 WHERE id = 10;
#UPDATE roles SET builtin = 11 WHERE id = 11;

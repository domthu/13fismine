
namespace :migrate do
  desc "imposta il campo ruolo_id"
  task :set_fs_roles => :environment do

    i=0
    no=0
    ye=0

    puts "\n..........................................\n"

    existing_users = User.all()
    for usr in existing_users do
      begin
        i += 1
        if usr.admin
          if usr.role_id != FeeConst::ROLE_ADMIN
            usr.role_id = FeeConst::ROLE_ADMIN
            usr.save
            ye +=1
            puts "[vip: " + i.to_s + "/" + ye.to_s + "/" + no.to_s + "] "
          end
        elsif usr.role_id.nil? || ((usr.role_id != FeeConst::ROLE_MANAGER) && (usr.role_id != FeeConst::ROLE_AUTHOR))
          #NON VA BENE
          #la gestione del ruolo
          usr.role_id = FeeConst::ROLE_REGISTERED
          usr.save
          ye +=1
          puts "[pubblico: " + i.to_s + "/" + ye.to_s + "/" + no.to_s + "] "
        else
          no += 1
        end
      end
    end
    puts "[rec: " + i.to_s + "/" + ye.to_s + "/" + no.to_s + "] "
    puts "\n..........................................\n"
    #[rec: 1955/704/1251]

  end
end

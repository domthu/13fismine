namespace :migrate do
  desc "fare una volta solo dopo avere creato tabella "
  task :move_errors => :environment do

    i=0
    no=0
    ye=0

    puts "\n..........................................\n"
    existing_email_type = EmailType.all()
    if (existing_email_type.nil?) || (existing_email_type.count < 1)
      EmailType.create!(:id => 1, :description => "newsletter")
      EmailType.create!(:id => 2, :description => "renew")
      EmailType.create!(:id => 3, :description => "register")
      EmailType.create!(:id => 4, :description => "password")
      EmailType.create!(:id => 5, :description => "proposal")
      EmailType.create!(:id => 6, :description => "email")
    end


    existing_nl = NewsletterUser.all(:limit => 10)
    for nl_usr in existing_nl do
      begin
        i += 1
        case (nl_usr.email_type)
          when 'email_type'
            nl_usr.email_type_id = 1
          when 'newsletter'
            nl_usr.email_type_id = 1
          else
            nl_usr.email_type_id = 1
        end
        if !nl_usr.errore.nil? && !nl_usr.errore.empty?
          info = Information.create!(:description => nl_usr.errore)
          nl_usr.information_id = info.id
          ye +=1
          puts "[info created: " + i.to_s + "/" + ye.to_s + "/" + no.to_s + "] nl(" + nl_usr.id.to_s + ")<-->(" + info.id.to_s + ")info"
        else
          no += 1
        end
        nl_usr.save
      end
    end
    puts "[rec: " + i.to_s + "/" + ye.to_s + "/" + no.to_s + "] "
    puts "\n..........................................\n"
    #[rec: 1955/704/1251]

  end
end

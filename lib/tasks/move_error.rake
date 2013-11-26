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

    #Subject is too long (maximum is 100 characters)
    #Information.create!(:description => "adkhasdklhasdklas")
    #Subject is too long (maximum is 100 characters)
    #Information.create!(:subject => nil, :description => "adkhasdklhasdklas")
    #Subject is too long (maximum is 100 characters)
    #Information.create!(:id => 1, :subject => nil, :description => "adkhasdklhasdklas")
#    info = Information.new
#    info.description = "adkhasdklhasdklas"
#    puts "[info created( " + (info.description.nil? ? "nil" : info.description.length.to_s) + "/" + ( info.subject.nil? ? "nil" : info.subject.length.to_s.to_s)
#    info.save
#    #info.save!

    #existing_nl = NewsletterUser.all(:limit => 100)
    existing_nl = NewsletterUser.all
    for nl_usr in existing_nl do
      begin
        i += 1
        if nl_usr.email_type_id == 0
          case (nl_usr.email_type)
            when 'email_type'
              nl_usr.email_type_id = 1
            when 'newsletter'
              nl_usr.email_type_id = 1
            else
              nl_usr.email_type_id = 1
          end

          #UPDATE `newsletter_users` SET email_type_id = 0 WHERE errore is not null or sended = 0
          #---> Kappao: html content result empty?
          if !nl_usr.errore.nil? && !nl_usr.errore.blank? # && !nl_usr.errore.empty?
            #puts "[  intermediate: " + i.to_s + "/" + ye.to_s + "/" + no.to_s + "] "
            #info = Information.create!(:subject => nil, :description => nl_usr.errore)
            #nl_usr.information_id = info.id
            info = Information.new
            if nl_usr.errore.length < 1000
              info.description = nl_usr.errore
            else
               info.description = truncate(nl_usr.errore, :length => 997, :omission => '...')
            end
            #puts "[info created(" + nl_usr.id.to_s + "): " + (info.description.nil? ? "nil" : info.description.length.to_s) + "/" + ( info.subject.nil? ? "nil" : info.subject.length.to_s.to_s)
            info.save!
            nl_usr.information = info
            ye +=1
            #@puts "[info created: " + i.to_s + "/" + ye.to_s + "/" + no.to_s + "] nl(" + nl_usr.id.to_s + ")<-->(" + info.id.to_s + ")info"
          else
            #puts "[info not created(" + nl_usr.id.to_s
            no += 1
          end
          nl_usr.save
        end
      end
    end
    puts "[rec: " + i.to_s + "/" + ye.to_s + "/" + no.to_s + "] "
    puts "\n..........................................\n"
    #[rec: 1955/704/1251]

  end
end

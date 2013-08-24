#require "#{RAILS_ROOT}/app/helpers/conventions_helper"
#include ConventionsHelper
#Attenzione installare la $ gem install hapricot
#require 'diff'
#require File.expand_path(File.dirname(__FILE__) + "/../undress/textile")

#we use this to get the image.
#require 'rest-open-uri'

namespace :migrate do
  desc "reccupera i vecchi allegati del sito e caricali dentro i campi attachments"
  task :load_old_attachments => :environment do
# $ rake migrate:load_old_attachments --trace
    i=0
    no=0
    ye=0
    imported=0

    require 'rubygems'
    require 'open-uri'
    require 'net/http'
    #require 'paperclip'
    VALID_EXTENSIONS =['pdf', 'jpg', 'doc', 'xls', 'PPT', 'pps', 'zip', 'bmp']
#pdf
#jpg
#doc
#xls
#PPT
#pps
#zip
#970
#, n
#civ
#0.R
#llo
#bmp
#28
#29
#5.U
#004
#e n
#010
#.06
#12
#.04
#.03
#3.d
#4.d
#15
#+16
#+st
#allegati
#3807 "Con la circolare 9E" --> 2 allegati
#3869
#3855  --> estensione .+st
#Attenzione http://www.fiscosport.it/Allegati/841.pdf

    puts "\n..........................................\n"

    #ATTACHMENT vanno a salvare nella cartella "Files nella root application. Present in .gitignore
    #puts File.join(File.dirname(__FILE__), '/../../files', "/Allegati/470.pps")
    #puts File.join('#{application_root}', "/Allegati/470.pps")
    dest_dir = Redmine::Configuration['attachments_storage_path'] || "#{Rails.root}/files"
    #puts dest_dir
    Dir.mkdir(dest_dir) unless File.exists?(dest_dir)
    #Dir.mkdir(dest_dir, 777) unless File.directory?(dest_dir)
    #Dir.mkdir(dest_dir, 777) unless File.dir?(dest_dir)
    #Dir.mkdir(dest_dir) unless Dir.exists?(dest_dir) Rails 3


    #existing_issues = Issue.all()
    #existing_attachments = Issue.all().limit(10)
    sql = "SELECT * FROM allegati_fs"
    ActiveRecord::Base.establish_connection
    existing_attachments = ActiveRecord::Base.connection.select_all(sql)
    #for record in existing_attachments do
    #existing_attachments.each do |hash, record|
    existing_attachments.each do |record|
      #`AL_IDAllegato` int(11) NOT NULL,
      #`AL_IDContenuto` int(11) DEFAULT NULL,
      #`AL_Descrizione` longtext,
      #`AL_URL` varchar(255) DEFAULT NULL,
      #`AL_Protetto` tinyint(4) DEFA
      #his row consists of a Hash with numerical and named access.
      begin
        i += 1
        #if imported > 2 || i > 5
        #  break
        #end
        id_att = record['AL_IDAllegato'].squish
        id_articolo = record['AL_IDContenuto'].squish
        description = record['AL_Descrizione'].squish
        filename_toload = record['AL_URL'].squish
        extension = filename_toload.last(3)
        AL_Protetto = record['AL_Protetto']
        if (extension && !extension.nil? && VALID_EXTENSIONS.include?(extension))

          ye += 1

          #find_articolo
          articolo = Issue.find_by_id(id_articolo.to_i)
          if articolo
            #puts '  ARTICOLO TROVATO (' + articolo.id.to_s + '): ' + articolo.to_s
            # see existing Attachments
            exist_yet = false
            articolo.attachments.each do |attachment|
              #next unless attachment.exist?
              #  attachment.open {
              #    a = Attachment.new :created_on => attachment.time
              #    a.file = attachment
              #    a.author = find_or_create_user(attachment.author)
              #    a.container = i
              #    a.description = attachment.description
              #    migrated_ticket_attachments += 1 if a.save
              #  }
              #puts '  EXISTING ATTACHMENT ()-----------' + attachment.filename
              if (attachment.filename == filename_toload)
                exist_yet = true
                #puts '  ALREADY EXIST do nothing'
                break
              end
            end

            if (exist_yet == false)
              puts "[rec: " + i.to_s + "/" + ye.to_s + "/" + no.to_s + "] --> " + extension + ',  description: ' + description
              puts '  ARTICOLO TROVATO (' + articolo.id.to_s + '): ' + articolo.to_s
              puts '    UPLOAD ATTACHMENT'
              #create new attachment
              attachment_url = 'http://www.fiscosport.it/Allegati/' + filename_toload
              #Parse URL
              attachment_uri=URI.parse(attachment_url)
              puts '    attachment host: ' + attachment_uri.host  + ', file: ' + File.basename(attachment_uri.path) + ', port: ' + attachment_uri.port.to_s + ', path: ' + attachment_uri.path
              puts '    complete file path: ' + File.join(dest_dir, filename_toload)
              #Get URL and retrieve data
              Net::HTTP.start(attachment_uri.host, attachment_uri.port) do |attHttp|
                req = Net::HTTP::Get.new(attachment_uri.path)
                #req.basic_auth 'dom_thual@yahoo.fr', 'a' #I need this because it is password protected, not needed if yours isn't
                resp = attHttp.request(req)
                content_type=resp.content_type()

                #Now create the fake uploaded file
                #attachment_file = ActionController::UploadedTempfile.new(filename_toload)
                #attachment_file = File.new("files/#{filename_toload.gsub(' ', '%20')}", 'w+')
                attachment_file = File.new(File.join(dest_dir, filename_toload), 'w+')
                attachment_file.binmode
                attachment_file.write(resp.body)
                #attachment_file.original_path = filename_toload  undefined method
                #attachment_file.content_type = resp.content_type
                attachment_file.rewind

                #Create attachment with the uploaded file and other settings defined earlier
                if articolo.author.nil?
                  articolo.author = User.find_by_id(2232)
                  articolo.save
                end
                new_attachment=Attachment.create(
                        :container => articolo,           #Issue object defined earlier
                        :file => attachment_file,
                        :description => description,
                        :author => articolo.author        #User object defined earlier
                )
                if new_attachment && File.exists?(new_attachment.diskfile)
                  imported += 1
                  puts '    UPLOAD & ATTACHED -----------FILE---------> ' + new_attachment.diskfile

                  ##Add to articolo if not yet
                  #articolo.attachments << new_attachment
                  #articolo.save
                else
                  puts '    NNNNNNNNOOOOOOOTTTTTTTT CREATED ()-----------' + filename_toload + '---------> ' + filename_toload
                end

                #Close temporary file
                #attachment_file.close!
                #delete temporary file  (Attachment create yyyymmddhhmmnn_file_name.extension)
                system "rm #{File.join(dest_dir, filename_toload)}"

                #a = Attachment.new :created_on => DateTime.now
                #a.file = attachment_file   #File.Open(url)
                #a.author = articolo.author
                #a.container = articolo
                #a.description = description
                #imported += 1 if a.save
              end

            end

          end

        else
          no += 1
          #puts 'Kappao -----------' + extension + '---------> ' + filename_toload
        end
        #puts "!!" + id_att +'/articolo: ' + id_articolo + "!!!!!\n\n"

      rescue Exception => e
        puts "\nEXCEPTION# #{e.message}\n"
      end
    end
    puts "\n..........................................\n"
    puts "FINAL [rec: " + i.to_s + "/" + ye.to_s + "/" + no.to_s + "]"
    puts "imported " + imported.to_s
#FINAL [rec: 572/512/60]
#imported 456  con limite a 5120 Kb
#imported 11  con limite a 15120 Kb
#imported 1  con limite a 50120 Kb  470.pps articolo 2502  5438464
#imported 8 cambia utente con 2232 in caso non c'è


#FINAL 479
  end
end

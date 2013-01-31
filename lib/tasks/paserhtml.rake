#use HTML::WikiConverter;

namespace :db do
  desc "Parse HTML to Wiki format using ?"
  task :parsehtml => :environment do
	
  #trovare quale dialect usa l'editore textile di REDMINE
  #wc = new HTML::WikiConverter( dialect => 'MediaWiki' ); 
  #print $wc->html2wiki( html => '<b>text</b>' ), "\n\n";
	
  #existing_articles Issue.all()
	#for articolo in existing_articles do
	#		tmp = wc.html2wiki( articolo.subject)
	#		articolo.subject = tmp
	#		tmp = wc.html2wiki( articolo.description)
	#		articolo.description = tmp
	#		tmp = wc.html2wiki( articolo.summary)
	#		articolo.summary = tmp
	#		articolo.save()
	#end

	#for articolo in existing_articles do
	#end
	
  end
end	
	

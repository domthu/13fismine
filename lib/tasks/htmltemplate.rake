
namespace :db do
  desc "Fill template with default data"
  task :htmltemplate => :environment do
    Template.create!(:name => "Header", :html => "", :active => 1)
    Template.create!(:name => "Footer", :html => "", :active => 1)
    Template.create!(:name => "Newsletter message", :html => "", :active => 1)
    Template.create!(:name => "Rilancio abbonamento", :html => "", :active => 1)
    Template.create!(:name => "Rilancio guest", :html => "", :active => 1)
    Template.create!(:name => "Non più abbonato", :html => "", :active => 1)
    Template.create!(:name => "registrato per power user", :html => "", :active => 1)
    Template.create!(:name => "Flash", :html => "", :active => 1)
    Template.create!(:name => "Informazione", :html => "", :active => 1)
  end
end

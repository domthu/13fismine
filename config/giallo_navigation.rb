# -*- coding: utf-8 -*-
# Configures your navigation
SimpleNavigation::Configuration.run do |navigation|
  # Specify the class that will be applied to active navigation items. Defaults to 'selected'
  navigation.selected_class = 'active'
  # Define the primary navigation
  navigation.items do |menu_generale|
    menu_generale.item :key_home, 'Home', editorial_path,  :highlights_on => %r(/editorial), :id => "editoriale"
    menu_generale.item :key_2, 'Chi Siamo', profiles_all_path, :highlights_on => %r(/chi-siamo)
    menu_generale.item :key_3, 'Cosa Offriamo', cosaoffriamo_path
    menu_generale.item :key_5, 'Lavora con Noi', lavoraconnoi_path
    menu_generale.item :key_6, 'Eventi e Convegni', eventi_path , :highlights_on => %r(/event)
   #menu_generale.item  @tmenu_ns.key, @tmenu_ns.description, '/editoriale/' + @tmenu_ns.key
    menu_generale.item :key_8, 'Abbonamenti', page_abbonamento_path,  :highlights_on => %r(/account)
   # menu_generale.item :key_8, 'Tuo abbonamento', abbonamenti_path, :if => Proc.new { User.current.logged? }
    menu_generale.item :key_7, 'Progetto Fiscosport', progettofs_path
    menu_generale.item :key_9, 'Contattaci', contattaci_path
    menu_generale.dom_class = 'fs-hmenu'
  end
end

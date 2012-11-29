# -*- coding: utf-8 -*-
# Configures your navigation
SimpleNavigation::Configuration.run do |navigation|

  # Specify the class that will be applied to active navigation items. Defaults to 'selected'
  navigation.selected_class = 'active'


  # Define the primary navigation
  navigation.items do |menu_generale|
    menu_generale.item :key_home, 'Home', home_path do |primary|
      primary.item :editoriale, 'Editoriale', home_path
      @top_menus = TopMenu.find(:all)

      @top_menus.each do |tmn|

        #map.top_menu_page 'editorial/:topmenu_key'

        primary.item tmn.key,
                     tmn.description,
                     '/editoriale/' + tmn.key, # + '/' + tmn.id.to_s,
                     :highlights_on => :subpath do |sub_nav1|

          #map.topsection_page '/editorial/:topmenu_key/sezione/:topsection_id',
          @top_sections = TopSection.find(:all, :conditions => ["top_menu_id = ?", tmn.id])
          @top_sections.each do |ts|
            sub_nav1.item tmn.key + ts.id.to_s, ts.name, '/editoriale/' + tmn.key + '/' + ts.key, # + topsection_page(ts),
                          :highlights_on => %r(/#{tmn.key}\/#{ts.key})


            #sub_nav1.dom_class = 'art-hmenu'

          end
          sub_nav1.dom_class='art-hmenu'
        end #primary.item
        primary.dom_class = 'fs-hmenu'
      end #top_menus

    end
    menu_generale.item :key_2, 'Chi Siamo', chisiamo_path
    menu_generale.item :key_3, 'Servizi alle Associazioni', servizi_path
    menu_generale.item :key_5, 'Lavora con Noi', lavora_path
    menu_generale.item :key_6, 'Convegni', convegni_path
    menu_generale.item :key_7, 'Enti e Federazioni', enti_path
    menu_generale.item :key_8, 'Abbonamenti', abbonamenti_path
    menu_generale.item :key_9, 'Quesiti', quesiti_path
    menu_generale.item :key_10, 'Contatti', contatti_path

    menu_generale.dom_class = 'fs-hmenu'


  end
end


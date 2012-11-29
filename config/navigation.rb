# -*- coding: utf-8 -*-
# Configures your navigation
SimpleNavigation::Configuration.run do |navigation|

  # Specify the class that will be applied to active navigation items. Defaults to 'selected'
  navigation.selected_class = 'active'


  # Define the primary navigation
  navigation.items do |menu_generale|
    menu_generale.item :key_home, 'name home', home_path, :highlights_on => :subpath do |primary|
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

            primary.dom_class = 'fs-hmenu'
            sub_nav1.dom_class='fs-hmenu'
            #sub_nav1.dom_class = 'art-hmenu'

          end

        end #primary.item

      end #top_menus

    end
    menu_generale.item :key_2, 'chi siamo', home_path, :highlights_on => :subpath
    menu_generale.item :key_3, 'servizi', home_path, :highlights_on => :subpath
    menu_generale.item :key_4, 'servizi4', home_path, :highlights_on => :subpath

    menu_generale.dom_class = 'fs-hmenu'
  end
end


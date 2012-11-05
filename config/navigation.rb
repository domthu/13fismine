# -*- coding: utf-8 -*-
# Configures your navigation
SimpleNavigation::Configuration.run do |navigation|

  # Specify the class that will be applied to active navigation items. Defaults to 'selected'
  navigation.selected_class = 'active'


  # Define the primary navigation
  navigation.items do |primary|

    @top_menus = TopMenu.find(:all)

    @top_menus.each do |tmn|

      #map.top_menu_page 'editorial/:topmenu_key'
      primary.item tmn.key,
          tmn.description,
          '/editorial/' + tmn.key, # + '/' + tmn.id.to_s,
          :highlights_on => :subpath do |sub_nav|

            #map.topsection_page '/editorial/:topmenu_key/sezione/:topsection_id',
            @top_sections = TopSection.find(:all, :conditions => ["top_menu_id = ?", tmn.id])
            @top_sections.each do |ts|
              sub_nav.item tmn.key + ts.id.to_s,
                  ts.name,
                  '/editorial/' + tmn.key + '/sezione/' + ts.id.to_s, # + topsection_page(ts),
                  :highlights_on => %r(/#{tmn.key}\/sezione\/#{ts.id.to_s})
              primary.dom_class = 'fs-hmenu'
              sub_nav.dom_class = 'fs-hmenu'
            end

      end #primary.item

    end #top_menus

  end
end

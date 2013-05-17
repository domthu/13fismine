# -*- coding: utf-8 -*-
# Configures your navigation
SimpleNavigation::Configuration.run do |navigation|

  # Specify the class that will be applied to active navigation items. Defaults to 'selected'
  navigation.selected_class = 'active'


  # Define the primary navigation
  navigation.items do |menu_generale|
    menu_generale.item :key_home, 'Home', editorial_path do |primary|
      primary.item :editoriale, 'Editoriale', editorial_path , :highlights_on => %r(/edizion)
      @top_menus = TopMenu.find(:all, :conditions => ["se_visibile = 1"])

      @top_menus.each do |tmn|

        #map.top_menu_page 'editorial/:topmenu_key'

        primary.item tmn.key,
                     tmn.description,
                     '/editoriale/' + tmn.key, # + '/' + tmn.id.to_s,
                     :highlights_on => :subpath do |sub_nav1|

          #map.topsection_page '/editorial/:topmenu_key/sezione/:topsection_id',
          @top_sections = TopSection.find(:all, :conditions => ["top_menu_id = #{tmn.id} AND hidden_menu = 0"])
          @top_sections.each do |ts|
            sub_nav1.item tmn.key + ts.id.to_s, ts.name, '/editoriale/' + tmn.key + '/' + ts.key,
                          :highlights_on => %r(/#{tmn.key}\/#{ts.key})
            #sub_nav1.dom_class = 'art-hmenu'

          end

          sub_nav1.dom_class='fs-menu2-hmenu'
        end #primary.item
        primary.dom_class = 'fs-menu2-hmenu'

      end #top_menus
      primary.item :q1, 'Quesiti', quesiti_all_path, :highlights_on => %r(/quesit) do |sub_q|
        sub_q.item :q2, 'Poni un quesito', quesito_new_path
        sub_q.item :q3, 'I miei quesiti', quesiti_my_path
        sub_q.item :q4, 'Le Risposte ai quesiti', quesiti_all_path
        primary.dom_class = 'fs-menu2-hmenu'
        sub_q.dom_class='fs-menu2-hmenu'

      end

    end
    @tmenu_ns = TopMenu.find_by_id(FeeConst::TMENU_NEWSPORT.to_s)
    menu_generale.item :key_2, 'Chi Siamo', '/chi-siamo'
    menu_generale.item :key_3, 'Cosa Offriamo', cosaoffriamo_path
    menu_generale.item :key_5, 'Lavora con Noi', lavoraconnoi_path
    menu_generale.item :key_6, 'Eventi e Convegni', eventi_path
    menu_generale.item  @tmenu_ns.key, @tmenu_ns.description, '/editoriale/' + @tmenu_ns.key
    menu_generale.item :key_8, 'Abbonamenti', abbonamenti_path
    menu_generale.item :key_7, 'Progetto Fiscosport', progettofs_path
    menu_generale.dom_class = 'fs-hmenu'


  end
end

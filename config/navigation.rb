# -*- coding: utf-8 -*-
# Configures your navigation
SimpleNavigation::Configuration.run do |navigation|
  # Specify a custom renderer if needed.
  # The default renderer is SimpleNavigation::Renderer::List which renders HTML lists.
  # The renderer can also be specified as option in the render_navigation call.
  # navigation.renderer = Your::Custom::Renderer

  # Specify the class that will be applied to active navigation items. Defaults to 'selected'
  navigation.selected_class = 'active'

  # Specify the class that will be applied to the current leaf of
  # active navigation items. Defaults to 'simple-navigation-active-leaf'
  # navigation.active_leaf_class = 'your_active_leaf_class'

  # Item keys are normally added to list items as id.
  # This setting turns that off
  # navigation.autogenerate_item_ids = false

  # You can override the default logic that is used to autogenerate the item ids.
  # To do this, define a Proc which takes the key of the current item as argument.
  # The example below would add a prefix to each key.
  # navigation.id_generator = Proc.new {|key| "my-prefix-#{key}"}

  # If you need to add custom html around item names, you can define a proc that will be called with the name you pass in to the navigation.
  # The example below shows how to wrap items spans.
  # navigation.name_generator = Proc.new {|name| "<span>#{name}</span>"}

  # The auto highlight feature is turned on by default.
  # This turns it off globally (for the whole plugin)
  # navigation.auto_highlight = false

  # Define the primary navigation
  navigation.items do |primary|
    # Add an item to the primary navigation. The following params apply:
    # key - a symbol which uniquely defines your navigation item in the scope of the primary_navigation
    # name - will be displayed in the rendered navigation. This can also be a call to your I18n-framework.
    # url - the address that the generated item links to. You can also use url_helpers (named routes, restful routes helper, url_for etc.)
    # options - can be used to specify attributes that will be included in the rendered navigation item (e.g. id, class etc.)
    #           some special options that can be set:
    #           :if - Specifies a proc to call to determine if the item should
    #                 be rendered (e.g. <tt>:if => Proc.new { current_user.admin? }</tt>). The
    #                 proc should evaluate to a true or false value and is evaluated in the context of the view.
    #           :unless - Specifies a proc to call to determine if the item should not
    #                     be rendered (e.g. <tt>:unless => Proc.new { current_user.admin? }</tt>). The
    #                     proc should evaluate to a true or false value and is evaluated in the context of the view.
    #           :method - Specifies the http-method for the generated link - default is :get.
    #           :highlights_on - if autohighlighting is turned off and/or you want to explicitly specify
    #                            when the item should be highlighted, you can set a regexp which is matched
    #                            against the current URI.  You may also use a proc, or the symbol <tt>:subpath</tt>. 
    #
    # primary.item :key_1, 'name', url, options

    # Add an item which has a sub navigation (same params, but with block)


    #sub_nav.item :s_1, 'Indice',home_path
    #sub_nav.item :s_2, 'Approfondimenti','/home/2'
    #sub_nav.item :s_5, 'Eventi','/home/eventi'
    #sub_nav.item :s_6, 'Quesiti','/home/quesiti'
    ##   sub_nav.item :v_0, 'Abbonamenti',subscription_home_index_path
    ##  sub_nav.item :special, '' , main_home_index_path , :highlights_on => /home\/(\d)+\/show_article/
    ## sub_nav.item :special, 'Ritorna' , main_home_index_path,    :highlights_on => /home\/[0-9]+\/show_article/
    ##  sub_nav.item :v_1, 'Ritorna' , main_home_index_path, /home\/[0-9]+\/show_article/)


    #   primary.item :home1, 'home(ver1)', editorial_path  :highlights_on => /(\/events/new)|(\/events)/

    primary.item :home, 'home', '/home/', :highlights_on => %r(/home) do |sub_nav|
      @top_sections = TopSection.find(:all, :conditions => "top_menu_id = 1")
      @top_sections.each do |ts|
        sub_nav.item 'home' + ts.id.to_s, ts.name, '/home' + sezione_path(ts),:highlights_on => %r(/home\/sezione\/#{ts.id.to_s})
        primary.dom_class = 'fs-hmenu'
        sub_nav.dom_class = 'fs-hmenu'
      end
    end

    primary.item :fisc, 'Area Fiscale', '/fiscale/2', :highlights_on => :subpath do |sub_nav|
      @top_sections = TopSection.find(:all, :conditions => "top_menu_id = 2")
      @top_sections.each do |ts|
        sub_nav.item 'fisc' + ts.id.to_s, ts.name,'/fiscale' + sezione_path(ts), :highlights_on => %r(/fiscale\/sezione\/#{ts.id.to_s})
        primary.dom_class = 'fs-hmenu'
        sub_nav.dom_class = 'fs-hmenu'
      end
    end
    primary.item :vade, 'Vademecum', '/guide/3', :highlights_on => :subpath do |sub_nav|
      @top_sections = TopSection.find(:all, :conditions => "top_menu_id = 3")
      @top_sections.each do |ts|
        sub_nav.item 'vade' + ts.id.to_s, ts.name,'/guide' +sezione_path(ts), :highlights_on => %r(/guide\/sezione\/#{ts.id.to_s})
        primary.dom_class = 'fs-hmenu'
        sub_nav.dom_class = 'fs-hmenu'
      end
    end

    primary.item :modu, 'Modulistica', '/modulistica/4', :highlights_on => :subpath do |sub_nav|
      @top_sections = TopSection.find(:all, :conditions => "top_menu_id = 4")
      @top_sections.each do |ts|
        sub_nav.item 'modu' + ts.id.to_s, ts.name,'/modulistica' + sezione_path(ts), :highlights_on => %r(/modulistica\/sezione\/#{ts.id.to_s})
        primary.dom_class = 'fs-hmenu'
        sub_nav.dom_class = 'fs-hmenu'
      end
    end

    primary.item :altr, 'Altri Temi', '/altri-temi/5', :highlights_on => :subpath do |sub_nav|
      @top_sections = TopSection.find(:all, :conditions => "top_menu_id = 5")
      @top_sections.each do |ts|
        sub_nav.item 'altr' + ts.id.to_s, ts.name, sezione_path(ts), :highlights_on => %r(#{sezione_path(ts)})
        primary.dom_class = 'fs-hmenu'
        sub_nav.dom_class = 'fs-hmenu'
      end
    end
    primary.item :vari, 'Varie', '/varie/6', :highlights_on => :subpath do |sub_nav|
      @top_sections = TopSection.find(:all, :conditions => "top_menu_id = 6")
      @top_sections.each do |ts|
        sub_nav.item 'vari' + ts.id.to_s, ts.name, sezione_path(ts), :highlights_on => %r(#{sezione_path(ts)})
        primary.dom_class = 'fs-hmenu'
        sub_nav.dom_class = 'fs-hmenu'
      end
    end
  end
end



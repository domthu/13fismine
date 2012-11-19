# -*- coding: utf-8 -*-
# Configures your navigation
SimpleNavigation::Configuration.run do |navigation|

  # Specify the class that will be applied to active navigation items. Defaults to 'selected'
  navigation.selected_class = 'active'
  navigation.items do |primary|
    primary.item :key_1, 'Home', home_path
    primary.item :key_2, 'Chi Siamo', chisiamo_path
    primary.item :key_3, 'Servizi', servizi_path

    #  primary.item :key_3, 'Admin', url, :class => 'special', :if => Proc.new{ current_account.admin? }
    # primary.item :key_4, 'Account', url, :unless => Proc.new { logged_in? }
    # primary.auto_highlight = false
    primary.dom_class = 'fs-hmenu-top'

  end

end

module InvoicesHelper
  def users_status_options_for_select(selected)
    user_count_by_status = User.count(:group => 'status').to_hash
    options_for_select([[l(:label_all), ''],
                        ["#{l(:status_active)} (#{user_count_by_status[1].to_i})", 1],
                        ["#{l(:status_registered)} (#{user_count_by_status[2].to_i})", 2],
                        ["#{l(:status_locked)} (#{user_count_by_status[3].to_i})", 3]], selected)
  end
end

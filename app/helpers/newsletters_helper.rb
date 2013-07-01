module NewslettersHelper
  include FeesHelper #getdate

  def users_roles_options_for_select(selected)
    user_count_by_role = FeeConst::NEWSLETTER_ROLES
    options_for_select([[l(:label_all), ''],
                        ["#{l(:role_abbonato)} (#{user_count_by_role[1].to_i})", 1],
                        ["#{l(:role_registered)} (#{user_count_by_role[2].to_i})", 2],
                        ["#{l(:role_renew)} (#{user_count_by_role[3].to_i})", 3]], selected)

  end

end

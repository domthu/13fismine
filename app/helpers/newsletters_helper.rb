module NewslettersHelper
  include FeesHelper #getdate

  def users_roles_options_for_select(selected)
    user_count_by_role = FeeConst::NEWSLETTER_ROLES
    arr = []
    user_count_by_role.each {|role|
      cnt = User.count(:conditions => ['role_id = ?', role.to_s])
      txt = "[" + role.to_s + "]" + l("role_" + cnt.to_s) + " (" + cnt.to_s + ")"
      arr << [txt, user_count_by_role[0]]
    }
    options_for_select(arr, selected)

#    options_for_select([
#      [l(:label_all_users), ''],
#      ["#{l(:role_abbonato)} (#{user_count_by_role[0].to_i})", user_count_by_role[0]],
#      ["#{l(:role_registered)} (#{user_count_by_role[1].to_i})", user_count_by_role[1]],
#      ["#{l(:role_renew)} (#{user_count_by_role[2].to_i})", user_count_by_role[2]]
#      ], selected)

  end

end

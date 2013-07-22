module NewslettersHelper
  include FeesHelper #getdate

#Obsolete usate FeesHelper fee_abbo_options_for_select
#  def users_roles_options_for_select(selected)
#    user_count_by_role = FeeConst::NEWSLETTER_ROLES
#    arr = []
#    user_count_by_role.each {|role|
#      cnt = User.count(:conditions => ['role_id = ?', role.to_s])
#      txt = "[" + role.to_s + "]" + l("role_" + cnt.to_s) + " (" + cnt.to_s + ")"
#      arr << [txt, user_count_by_role[0]]
#    }
#    options_for_select(arr, selected)
#  end

end

require 'test_helper'

class GroupBannersControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:group_banners)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create group_banner" do
    assert_difference('GroupBanner.count') do
      post :create, :group_banner => { }
    end

    assert_redirected_to group_banner_path(assigns(:group_banner))
  end

  test "should show group_banner" do
    get :show, :id => group_banners(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => group_banners(:one).to_param
    assert_response :success
  end

  test "should update group_banner" do
    put :update, :id => group_banners(:one).to_param, :group_banner => { }
    assert_redirected_to group_banner_path(assigns(:group_banner))
  end

  test "should destroy group_banner" do
    assert_difference('GroupBanner.count', -1) do
      delete :destroy, :id => group_banners(:one).to_param
    end

    assert_redirected_to group_banners_path
  end
end

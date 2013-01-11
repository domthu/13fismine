require 'test_helper'

class UserProfilesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:user_profiles)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create user_profile" do
    assert_difference('UserProfile.count') do
      post :create, :user_profile => { }
    end

    assert_redirected_to user_profile_path(assigns(:user_profile))
  end

  test "should show user_profile" do
    get :show, :id => user_profiles(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => user_profiles(:one).to_param
    assert_response :success
  end

  test "should update user_profile" do
    put :update, :id => user_profiles(:one).to_param, :user_profile => { }
    assert_redirected_to user_profile_path(assigns(:user_profile))
  end

  test "should destroy user_profile" do
    assert_difference('UserProfile.count', -1) do
      delete :destroy, :id => user_profiles(:one).to_param
    end

    assert_redirected_to user_profiles_path
  end
end

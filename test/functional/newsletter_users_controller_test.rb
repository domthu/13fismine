require 'test_helper'

class NewsletterUsersControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:newsletter_users)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create newsletter_user" do
    assert_difference('NewsletterUser.count') do
      post :create, :newsletter_user => { }
    end

    assert_redirected_to newsletter_user_path(assigns(:newsletter_user))
  end

  test "should show newsletter_user" do
    get :show, :id => newsletter_users(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => newsletter_users(:one).to_param
    assert_response :success
  end

  test "should update newsletter_user" do
    put :update, :id => newsletter_users(:one).to_param, :newsletter_user => { }
    assert_redirected_to newsletter_user_path(assigns(:newsletter_user))
  end

  test "should destroy newsletter_user" do
    assert_difference('NewsletterUser.count', -1) do
      delete :destroy, :id => newsletter_users(:one).to_param
    end

    assert_redirected_to newsletter_users_path
  end
end

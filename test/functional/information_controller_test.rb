require 'test_helper'

class InformationControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:information)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create information" do
    assert_difference('Information.count') do
      post :create, :information => { }
    end

    assert_redirected_to information_path(assigns(:information))
  end

  test "should show information" do
    get :show, :id => information(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => information(:one).to_param
    assert_response :success
  end

  test "should update information" do
    put :update, :id => information(:one).to_param, :information => { }
    assert_redirected_to information_path(assigns(:information))
  end

  test "should destroy information" do
    assert_difference('Information.count', -1) do
      delete :destroy, :id => information(:one).to_param
    end

    assert_redirected_to information_path
  end
end

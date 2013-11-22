require 'test_helper'

class TopMenusControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:top_menus)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create top_menu" do
    assert_difference('TopMenu.count') do
      post :create, :top_menu => { }
    end

    assert_redirected_to top_menu_path(assigns(:top_menu))
  end

  test "should show top_menu" do
    get :show, :id => top_menus(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => top_menus(:one).to_param
    assert_response :success
  end

  test "should update top_menu" do
    put :update, :id => top_menus(:one).to_param, :top_menu => { }
    assert_redirected_to top_menu_path(assigns(:top_menu))
  end

  test "should destroy top_menu" do
    assert_difference('TopMenu.count', -1) do
      delete :destroy, :id => top_menus(:one).to_param
    end

    assert_redirected_to top_menus_path
  end
end

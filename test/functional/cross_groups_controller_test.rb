require 'test_helper'

class CrossGroupsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:cross_groups)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create cross_group" do
    assert_difference('CrossGroup.count') do
      post :create, :cross_group => { }
    end

    assert_redirected_to cross_group_path(assigns(:cross_group))
  end

  test "should show cross_group" do
    get :show, :id => cross_groups(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => cross_groups(:one).to_param
    assert_response :success
  end

  test "should update cross_group" do
    put :update, :id => cross_groups(:one).to_param, :cross_group => { }
    assert_redirected_to cross_group_path(assigns(:cross_group))
  end

  test "should destroy cross_group" do
    assert_difference('CrossGroup.count', -1) do
      delete :destroy, :id => cross_groups(:one).to_param
    end

    assert_redirected_to cross_groups_path
  end
end

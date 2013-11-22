require 'test_helper'

class CrossOrganizationsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:cross_organizations)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create cross_organization" do
    assert_difference('CrossOrganization.count') do
      post :create, :cross_organization => { }
    end

    assert_redirected_to cross_organization_path(assigns(:cross_organization))
  end

  test "should show cross_organization" do
    get :show, :id => cross_organizations(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => cross_organizations(:one).to_param
    assert_response :success
  end

  test "should update cross_organization" do
    put :update, :id => cross_organizations(:one).to_param, :cross_organization => { }
    assert_redirected_to cross_organization_path(assigns(:cross_organization))
  end

  test "should destroy cross_organization" do
    assert_difference('CrossOrganization.count', -1) do
      delete :destroy, :id => cross_organizations(:one).to_param
    end

    assert_redirected_to cross_organizations_path
  end
end

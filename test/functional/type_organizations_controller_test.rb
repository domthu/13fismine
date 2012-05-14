require 'test_helper'

class TypeOrganizationsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:type_organizations)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create type_organization" do
    assert_difference('TypeOrganization.count') do
      post :create, :type_organization => { }
    end

    assert_redirected_to type_organization_path(assigns(:type_organization))
  end

  test "should show type_organization" do
    get :show, :id => type_organizations(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => type_organizations(:one).to_param
    assert_response :success
  end

  test "should update type_organization" do
    put :update, :id => type_organizations(:one).to_param, :type_organization => { }
    assert_redirected_to type_organization_path(assigns(:type_organization))
  end

  test "should destroy type_organization" do
    assert_difference('TypeOrganization.count', -1) do
      delete :destroy, :id => type_organizations(:one).to_param
    end

    assert_redirected_to type_organizations_path
  end
end

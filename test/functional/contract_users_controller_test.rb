require 'test_helper'

class ContractUsersControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:contract_users)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create contract_user" do
    assert_difference('ContractUser.count') do
      post :create, :contract_user => { }
    end

    assert_redirected_to contract_user_path(assigns(:contract_user))
  end

  test "should show contract_user" do
    get :show, :id => contract_users(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => contract_users(:one).to_param
    assert_response :success
  end

  test "should update contract_user" do
    put :update, :id => contract_users(:one).to_param, :contract_user => { }
    assert_redirected_to contract_user_path(assigns(:contract_user))
  end

  test "should destroy contract_user" do
    assert_difference('ContractUser.count', -1) do
      delete :destroy, :id => contract_users(:one).to_param
    end

    assert_redirected_to contract_users_path
  end
end

require 'test_helper'

class AssosControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:assos)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create asso" do
    assert_difference('Asso.count') do
      post :create, :asso => { }
    end

    assert_redirected_to asso_path(assigns(:asso))
  end

  test "should show asso" do
    get :show, :id => assos(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => assos(:one).to_param
    assert_response :success
  end

  test "should update asso" do
    put :update, :id => assos(:one).to_param, :asso => { }
    assert_redirected_to asso_path(assigns(:asso))
  end

  test "should destroy asso" do
    assert_difference('Asso.count', -1) do
      delete :destroy, :id => assos(:one).to_param
    end

    assert_redirected_to assos_path
  end
end

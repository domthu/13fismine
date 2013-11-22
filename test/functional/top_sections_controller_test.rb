require 'test_helper'

class TopSectionsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:top_sections)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create top_section" do
    assert_difference('TopSection.count') do
      post :create, :top_section => { }
    end

    assert_redirected_to top_section_path(assigns(:top_section))
  end

  test "should show top_section" do
    get :show, :id => top_sections(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => top_sections(:one).to_param
    assert_response :success
  end

  test "should update top_section" do
    put :update, :id => top_sections(:one).to_param, :top_section => { }
    assert_redirected_to top_section_path(assigns(:top_section))
  end

  test "should destroy top_section" do
    assert_difference('TopSection.count', -1) do
      delete :destroy, :id => top_sections(:one).to_param
    end

    assert_redirected_to top_sections_path
  end
end

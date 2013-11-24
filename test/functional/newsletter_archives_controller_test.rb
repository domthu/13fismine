require 'test_helper'

class NewsletterArchivesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:newsletter_archives)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create newsletter_archive" do
    assert_difference('NewsletterArchive.count') do
      post :create, :newsletter_archive => { }
    end

    assert_redirected_to newsletter_archive_path(assigns(:newsletter_archive))
  end

  test "should show newsletter_archive" do
    get :show, :id => newsletter_archives(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => newsletter_archives(:one).to_param
    assert_response :success
  end

  test "should update newsletter_archive" do
    put :update, :id => newsletter_archives(:one).to_param, :newsletter_archive => { }
    assert_redirected_to newsletter_archive_path(assigns(:newsletter_archive))
  end

  test "should destroy newsletter_archive" do
    assert_difference('NewsletterArchive.count', -1) do
      delete :destroy, :id => newsletter_archives(:one).to_param
    end

    assert_redirected_to newsletter_archives_path
  end
end

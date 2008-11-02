require 'test_helper'

class <%= class_name %> < ActiveRecord::Base
  @@in_append_error = false
  
  def self.append_error
    @@in_append_error = true
    begin
      yield if block_given?
    ensure
      @@in_append_error = false
    end
  end

  def validate
    super
    errors.add_to_base('some error occurred') if @@in_append_error
  end

  def destroy
    errors.add_to_base('some error occurred') if @@in_append_error
    super if errors.empty?
  end
end

class <%= controller_class_name %>ControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:<%= controller_singular_name.pluralize %>)
    assert_template 'index'
  end

  def test_should_get_index_by_xhr
    xhr :get, :index
    assert_response :success
    assert_not_nil assigns(:<%= controller_singular_name.pluralize %>)
    assert_template '_index'
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_get_new_by_xhr
    xhr :get, :new
    assert_response :success
    assert_template '_new'
  end

  def test_should_create_<%= file_name %>
    assert_difference('<%= class_name %>.count') do
      post :create, :<%= controller_singular_name %> => <%= attrs_expression_for_test %>
    end
    assert_redirected_to <%= controller_resource_name_singularized %>_path(assigns(:<%= controller_singular_name %>))
  end

  def test_should_create_<%= file_name %>_by_xhr
    assert_difference('<%= class_name %>.count') do
      xhr :post, :create, :<%= controller_singular_name %> => <%= attrs_expression_for_test %>
    end
    assigns(:<%= controller_singular_name %>)
    assert_response :success
    assert_template '_show'
  end

  def test_should_show_<%= file_name %>
    get :show, :id => <%= table_name %>(:one).id
    assert_response :success
    assert_template 'show'
  end

  def test_should_show_<%= file_name %>_by_xhr
    xhr :get, :show, :id => <%= table_name %>(:one).id
    assert_response :success
    assert_template '_show'
  end

  def test_should_get_edit
    get :edit, :id => <%= table_name %>(:one).id
    assert_response :success
    assert_template 'edit'
  end

  def test_should_get_edit_by_xhr
    xhr :get, :edit, :id => <%= table_name %>(:one).id
    assert_response :success
    assert_template '_edit'
  end

  def test_should_update_<%= file_name %>
    put :update, :id => <%= table_name %>(:one).id, :<%= controller_singular_name %> => <%= attrs_expression_for_test %>
    assert_redirected_to <%= controller_resource_name_singularized %>_path(assigns(:<%= controller_singular_name %>))
  end

  def test_should_update_<%= file_name %>_by_xhr
    xhr :put, :update, :id => <%= table_name %>(:one).id, :<%= controller_singular_name %> => <%= attrs_expression_for_test %>
    assigns(:<%= controller_singular_name %>)
    assert_response :success
    assert_template '_show'
  end

  def test_should_destroy_<%= file_name %>
    assert_difference('<%= class_name %>.count', -1) do
      delete :destroy, :id => <%= table_name %>(:one).id
    end
    assert_redirected_to <%= controller_resource_name %>_path
  end

  def test_should_destroy_<%= file_name %>_by_xhr
    assert_difference('<%= class_name %>.count', -1) do
      xhr :delete, :destroy, :id => <%= table_name %>(:one).id
    end
    assert_response :success
  end



  def test_should_not_create_<%= file_name %>_with_error
    <%= class_name %>.append_error do 
      assert_no_difference('<%= class_name %>.count') do
        post :create, :<%= controller_singular_name %> => <%= attrs_expression_for_test %>
      end
      assigns(:<%= controller_singular_name %>)
      assert_response :success
      assert_template 'new'
    end
  end

  def test_should_not_create_<%= file_name %>_with_error_by_xhr
    <%= class_name %>.append_error do 
      assert_no_difference('<%= class_name %>.count') do
        xhr :post, :create, :<%= controller_singular_name %> => <%= attrs_expression_for_test %>
      end
      assigns(:<%= controller_singular_name %>)
      assert_response :success
      assert_template '_new'
    end
  end

  def test_should_not_update_<%= file_name %>_with_error
    <%= class_name %>.append_error do 
      put :update, :id => <%= table_name %>(:one).id, :<%= controller_singular_name %> => <%= attrs_expression_for_test %>
      assigns(:<%= controller_singular_name %>)
      assert_response :success
      assert_template 'edit'
    end
  end

  def test_should_not_update_<%= file_name %>_with_error_by_xhr
    <%= class_name %>.append_error do 
      xhr :put, :update, :id => <%= table_name %>(:one).id, :<%= controller_singular_name %> => <%= attrs_expression_for_test %>
      assigns(:<%= controller_singular_name %>)
      assert_response :success
      assert_template '_edit'
    end
  end

  def test_should_not_destroy_<%= file_name %>_with_error
    <%= class_name %>.append_error do 
      assert_no_difference('<%= class_name %>.count', -1) do
        delete :destroy, :id => <%= table_name %>(:one).id
      end
      assigns(:<%= controller_singular_name %>)
      assert_response :success
      assert_template 'edit'
    end
  end

  def test_should_not_destroy_<%= file_name %>_with_error_by_xhr
    <%= class_name %>.append_error do 
      assert_no_difference('<%= class_name %>.count', -1) do
        xhr :delete, :destroy, :id => <%= table_name %>(:one).id
      end
      assigns(:<%= controller_singular_name %>)
      assert_response :success
      assert_template '_edit'
    end
  end
end

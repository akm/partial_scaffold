require File.join(File.dirname(__FILE__), '..'<%= ", '..'" * controller_class_path.length %>, 'spec_helper')

describe <%= controller_class_name %>Controller do

  def mock_<%= controller_singular_name %>(stubs={})
    @mock_<%= controller_singular_name %> ||= mock_model(<%= class_name %>, stubs)
  end

  describe "responding to GET index" do
    describe " for non ajax request" do
      it "should expose all <%= controller_plural_name %> as @<%= controller_plural_name %>" do
        <%= class_name %>.should_receive(:find).with(:all).and_return([mock_<%= controller_singular_name %>])
        get(:index)
        response.should be_success
        response.should render_template("index")
        assigns[:<%= controller_plural_name %>].should == [mock_<%= controller_singular_name %>]
      end

      describe "with mime type of xml" do
        it "should render all <%= controller_plural_name %> as xml" do
          request.env["HTTP_ACCEPT"] = "application/xml"
          <%= class_name %>.should_receive(:find).with(:all).and_return(<%= controller_plural_name %> = mock("Array of <%= class_name %>"))
          <%= controller_plural_name %>.should_receive(:to_xml).and_return("generated XML")
          get(:index)
          response.should be_success
          response.body.should == "generated XML"
        end
      end
    end

    describe "for ajax request" do
      it "should expose all <%= controller_plural_name %> as @<%= controller_plural_name %>" do
        <%= class_name %>.should_receive(:find).with(:all).and_return([mock_<%= controller_singular_name %>])
        xhr :get, :index
        response.should be_success
        response.should render_template("_index")
        assigns[:<%= controller_plural_name %>].should == [mock_<%= controller_singular_name %>]
      end
    end
  end

  describe "responding to GET new" do
    describe "for non ajax request" do
      it "should expose a new <%= controller_singular_name %> as @<%= controller_singular_name %>" do
        mock_obj = mock_<%= controller_singular_name %>
<% if route_primary_key_name -%>
        mock_obj.should_receive(:<%= route_primary_key_name %>=).with(nil)
<% end -%>
        <%= class_name %>.should_receive(:new).and_return(mock_obj)
        get :new
        response.should be_success
        response.should render_template("new")
        assigns[:<%= controller_singular_name %>].should equal(mock_<%= controller_singular_name %>)
      end
    end

    describe "for ajax request" do
      it "should expose a new <%= controller_singular_name %> as @<%= controller_singular_name %> with XMLHttpRequest" do
        mock_obj = mock_<%= controller_singular_name %>
<% if route_primary_key_name -%>
        mock_obj.should_receive(:<%= route_primary_key_name %>=).with('1')
<% end -%>
        <%= class_name %>.should_receive(:new).and_return(mock_obj)
<% if route_primary_key_name -%>
        xhr :get, :new, :<%= route_primary_key_name %> => '1'
<% else -%>
        xhr :get, :new
<% end -%>
        response.should be_success
        response.should render_template("_new")
        assigns[:<%= controller_singular_name %>].should equal(mock_<%= controller_singular_name %>)
      end
    end
  end


  describe "responding to POST create" do
    describe "with valid params" do
      it "should expose a newly created <%= controller_singular_name %> as @<%= controller_singular_name %>" do
        <%= class_name %>.should_receive(:new).with({'these' => 'params'}).and_return(mock_<%= controller_singular_name %>(:save => true))
        post :create, :<%= controller_singular_name %> => {:these => 'params'}
        assigns(:<%= controller_singular_name %>).should equal(mock_<%= controller_singular_name %>)
      end

      describe "for non ajax request" do
        it "should redirect to the created <%= controller_singular_name %>" do
          <%= class_name %>.stub!(:new).and_return(mock_<%= controller_singular_name %>(:save => true))
          post :create, :<%= controller_singular_name %> => {}
          response.should redirect_to(:controller => '<%= controller_name %>', :action => 'show', :id => mock_<%= controller_singular_name %>.id)
        end
      end

      describe "for ajax request" do
        it "should redirect to the created <%= controller_singular_name %>" do
          <%= class_name %>.stub!(:new).and_return(mock_<%= controller_singular_name %>(:save => true))
          xhr :post, :create, :<%= controller_singular_name %> => {}
          response.should be_success
          response.should render_template("_show")
        end
      end
    end

    describe "with invalid params" do
      it "should expose a newly created but unsaved <%= controller_singular_name %> as @<%= controller_singular_name %>" do
        <%= class_name %>.stub!(:new).with({'these' => 'params'}).and_return(mock_<%= controller_singular_name %>(:save => false))
        post :create, :<%= controller_singular_name %> => {:these => 'params'}
        assigns(:<%= controller_singular_name %>).should equal(mock_<%= controller_singular_name %>)
      end

      describe "for non ajax request" do
        it "should re-render the 'new' template" do
          <%= class_name %>.stub!(:new).and_return(mock_<%= controller_singular_name %>(:save => false))
          post :create, :<%= controller_singular_name %> => {}
          response.should render_template('new')
        end
      end

      describe "for ajax request" do
        it "should re-render the 'new' template" do
          <%= class_name %>.stub!(:new).and_return(mock_<%= controller_singular_name %>(:save => false))
          xhr :post, :create, :<%= controller_singular_name %> => {}
          response.should render_template('_new')
        end
      end
    end
  end

  describe "responding to GET show" do
    describe "for non ajax request" do
      it "should expose the requested <%= controller_singular_name %> as @<%= controller_singular_name %>" do
        <%= class_name %>.should_receive(:find).with("37").and_return(mock_<%= controller_singular_name %>)
        get :show, :id => "37"
        assigns[:<%= controller_singular_name %>].should equal(mock_<%= controller_singular_name %>)
      end

      describe "with mime type of xml" do
        it "should render the requested <%= controller_singular_name %> as xml" do
          request.env["HTTP_ACCEPT"] = "application/xml"
          <%= class_name %>.should_receive(:find).with("37").and_return(mock_<%= controller_singular_name %>)
          mock_<%= controller_singular_name %>.should_receive(:to_xml).and_return("generated XML")
          get :show, :id => "37"
          response.body.should == "generated XML"
        end
      end
    end

    describe "for ajax request" do
      it "should expose the requested <%= controller_singular_name %> as @<%= controller_singular_name %>" do
        <%= class_name %>.should_receive(:find).with("37").and_return(mock_<%= controller_singular_name %>)
        xhr :get, :show, :id => "37"
        assigns[:<%= controller_singular_name %>].should equal(mock_<%= controller_singular_name %>)
      end
    end
  end

  describe "responding to GET edit" do
    describe "for ajax request" do
      it "should expose the requested <%= controller_singular_name %> as @<%= controller_singular_name %>" do
        <%= class_name %>.should_receive(:find).with("37").and_return(mock_<%= controller_singular_name %>)
        get :edit, :id => "37"
        assigns[:<%= controller_singular_name %>].should equal(mock_<%= controller_singular_name %>)
      end
    end

    describe "for ajax request" do
      it "should expose the requested <%= controller_singular_name %> as @<%= controller_singular_name %>" do
        <%= class_name %>.should_receive(:find).with("37").and_return(mock_<%= controller_singular_name %>)
        xhr :get, :edit, :id => "37"
        assigns[:<%= controller_singular_name %>].should equal(mock_<%= controller_singular_name %>)
      end
    end
  end

  describe "responding to PUT udpate" do
    describe "with valid params" do
      it "should update the requested <%= controller_singular_name %>" do
        <%= class_name %>.should_receive(:find).with("37").and_return(mock_<%= controller_singular_name %>)
        mock_<%= controller_singular_name %>.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :<%= controller_singular_name %> => {:these => 'params'}
      end

      it "should expose the requested <%= controller_singular_name %> as @<%= controller_singular_name %>" do
        <%= class_name %>.stub!(:find).and_return(mock_<%= controller_singular_name %>(:update_attributes => true))
        put :update, :id => "1"
        assigns(:<%= controller_singular_name %>).should equal(mock_<%= controller_singular_name %>)
      end

      describe "for non ajax request" do
        it "should redirect to the <%= controller_singular_name %>" do
          <%= class_name %>.stub!(:find).and_return(mock_<%= controller_singular_name %>(:update_attributes => true))
          put :update, :id => "1"
          response.should redirect_to(:controller => '<%= controller_name %>', :action => 'show', :id => mock_<%= controller_singular_name %>.id)
        end
      end

      describe "for ajax request" do
        it "should redirect to the <%= controller_singular_name %>" do
          <%= class_name %>.stub!(:find).and_return(mock_<%= controller_singular_name %>(:update_attributes => true))
          xhr :put, :update, :id => "1"
          response.should be_success
          response.should render_template("_show")
        end
      end
    end
    
    describe "with invalid params" do
      it "should update the requested <%= controller_singular_name %>" do
        <%= class_name %>.should_receive(:find).with("37").and_return(mock_<%= controller_singular_name %>)
        mock_<%= controller_singular_name %>.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => "37", :<%= controller_singular_name %> => {:these => 'params'}
      end

      it "should expose the <%= controller_singular_name %> as @<%= controller_singular_name %>" do
        <%= class_name %>.stub!(:find).and_return(mock_<%= controller_singular_name %>(:update_attributes => false))
        put :update, :id => "1"
        assigns(:<%= controller_singular_name %>).should equal(mock_<%= controller_singular_name %>)
      end

      describe "for non ajax request" do
        it "should re-render the 'edit' template" do
          <%= class_name %>.stub!(:find).and_return(mock_<%= controller_singular_name %>(:update_attributes => false))
          put :update, :id => "1"
          response.should be_success
          response.should render_template('edit')
        end
      end

      describe "for ajax request" do
        it "should re-render the 'edit' template" do
          <%= class_name %>.stub!(:find).and_return(mock_<%= controller_singular_name %>(:update_attributes => false))
          xhr :put, :update, :id => "1"
          response.should be_success
          response.should render_template("_edit")
        end
      end
    end
  end

  describe "responding to DELETE destroy" do
    describe "with valid params" do
      it "should destroy the requested <%= controller_singular_name %>" do
        mock_obj = mock_<%= controller_singular_name %>
        mock_obj.should_receive(:destroy)
        mock_obj.should_receive(:errors).and_return([])
        <%= class_name %>.should_receive(:find).with("37").and_return(mock_obj)
        delete :destroy, :id => "37"
      end

      describe "for non ajax request" do
        it "should redirect to the <%= controller_plural_name %> list" do
          mock_obj = mock_<%= controller_singular_name %>(:destroy => true)
          mock_obj.should_receive(:errors).and_return([])
          <%= class_name %>.stub!(:find).and_return(mock_obj)
          delete :destroy, :id => "1"
          response.should redirect_to(:controller => '<%= controller_name %>', :action => 'index')
        end
      end

      describe "for ajax request" do
        it "should redirect to the <%= controller_plural_name %> list" do
          mock_obj = mock_<%= controller_singular_name %>(:destroy => true)
          mock_obj.should_receive(:errors).and_return([])
          <%= class_name %>.stub!(:find).and_return(mock_obj)
          xhr :delete, :destroy, :id => "1"
          response.should be_success
          response.body.strip.should == ""
        end
      end
    end

    describe "with invalid params" do
      it "should not destroy the requested <%= controller_singular_name %>" do
        mock_obj = mock_<%= controller_singular_name %>
        mock_obj.should_receive(:destroy)
        mock_obj.should_receive(:errors).and_return(['some error'])
        <%= class_name %>.should_receive(:find).with("37").and_return(mock_obj)
        delete :destroy, :id => "37"
      end

      describe "for non ajax request" do
        it "should redirect to the <%= controller_plural_name %> list" do
          mock_obj = mock_<%= controller_singular_name %>(:destroy => false)
          mock_obj.should_receive(:errors).and_return(['some error'])
          <%= class_name %>.stub!(:find).and_return(mock_obj)
          delete :destroy, :id => "1"
          response.should be_success
          response.should render_template("edit")
        end
      end

      describe "for ajax request" do
        it "should redirect to the <%= controller_plural_name %> list" do
          mock_obj = mock_<%= controller_singular_name %>(:destroy => true)
          mock_obj.should_receive(:errors).and_return(['some error'])
          <%= class_name %>.stub!(:find).and_return(mock_obj)
          xhr :delete, :destroy, :id => "1"
          response.should be_success
          response.should render_template("_edit")
        end
      end
    end
  end
end

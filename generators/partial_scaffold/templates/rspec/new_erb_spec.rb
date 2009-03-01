require File.join(File.dirname(__FILE__), '..', '..'<%= ", '..'" * controller_class_path.length %>, 'spec_helper')

<% output_attributes = attributes.reject{|attribute| [:datetime, :timestamp, :time, :date].index(attribute.type) } -%>
describe "/<%= table_name %>/new.<%= default_file_extension %>" do
  include <%= controller_class_name %>Helper
  
  before(:each) do
    assigns[:<%= controller_singular_name %>] = stub_model(<%= class_name %>,
      :new_record? => true<%= output_attributes.empty? ? '' : ',' %>
<% output_attributes.each_with_index do |attribute, attribute_index| -%>
      :<%= attribute.name %> => <%= attribute.default_value %><%= attribute_index == output_attributes.length - 1 ? '' : ','%>
<% end -%>
    )
  end

  it "should render new form" do
    mock_partial_scaffold = mock('partial_scaffold')
    mock_partial_scaffold.stub!(:js_var_name)
    mock_partial_scaffold.stub!(:setup_new)
    mock_partial_scaffold.stub!(:setup_actions)
    mock_partial_scaffold.should_receive(:initialize_js).and_return("1234567890")
    template.stub!(:partial_scaffold).and_return(mock_partial_scaffold)
    render "/<%= controller_name %>/new.<%= default_file_extension %>"
    
    # response.should have_tag("form[action=?][method=post]", <%= table_name %>_path) do
<% for attribute in output_attributes -%>
      with_tag("<%= attribute.input_type -%>#<%= controller_singular_name %>_<%= attribute.name %>[name=?]", "<%= controller_singular_name %>[<%= attribute.name %>]")
<% end -%>
    # end
  end
end



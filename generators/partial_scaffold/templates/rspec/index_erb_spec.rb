require File.join(File.dirname(__FILE__), '..', '..'<%= ", '..'" * controller_class_path.length %>, 'spec_helper')

<% output_attributes = attributes.reject{|attribute| [:datetime, :timestamp, :time, :date].index(attribute.type) } -%>
describe "/<%= table_name %>/index.<%= default_file_extension %>" do
  include <%= controller_class_name %>Helper
  
  before(:each) do
    assigns[:<%= controller_plural_name %>] = [
<% [1,2].each_with_index do |id, model_index| -%>
      stub_model(<%= class_name %><%= output_attributes.empty? ? (model_index == 1 ? ')' : '),') : ',' %>
<% output_attributes.each_with_index do |attribute, attribute_index| -%>
        :<%= attribute.name %> => <%= attribute.default_value %><%= attribute_index == output_attributes.length - 1 ? '' : ','%>
<% end -%>
<% if !output_attributes.empty? -%>
      <%= model_index == 1 ? ')' : '),' %>
<% end -%>
<% end -%>
    ]
  end

  it "should render list of <%= table_name %>" do
    render "/<%= controller_name %>/index.<%= default_file_extension %>"
<% for attribute in output_attributes -%>
    response.should have_tag("tr>td", <%= attribute.default_value %>.to_s, 2)
<% end -%>
  end
end


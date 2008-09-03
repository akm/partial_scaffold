# require 'restful_authentication/rails_commands'
class PartialScaffoldSubGenerator < Rails::Generator::NamedBase
  class Attribute < Rails::Generator::GeneratedAttribute
    def initialize(column)
      @column = column
      @name, @type = column.name, column.type.to_sym
    end
  end
  
  default_options :generate_action_views => false, :add_timestamps => false
  
  attr_reader   :foreign_key_name
  attr_reader   :controller_name,
                :controller_class_path,
                :controller_file_path,
                :controller_class_nesting,
                :controller_class_nesting_depth,
                :controller_class_name,
                :controller_singular_name,
                :controller_plural_name,
                :controller_file_name
  alias_method  :controller_table_name, :controller_plural_name

  def initialize(runtime_args, runtime_options = {})
    super
    @controller_name = @args.shift || @name.pluralize
    @foreign_key_name = @args.shift
    
    # sessions controller
    base_name, @controller_class_path, @controller_file_path, @controller_class_nesting, @controller_class_nesting_depth = extract_modules(@controller_name)
    @controller_class_name_without_nesting, @controller_file_name, @controller_plural_name = inflect_names(base_name)
    @controller_singular_name = @controller_file_name.singularize

    @controller_class_name = @controller_class_nesting.empty? ?
    @controller_class_name_without_nesting :
      "#{@controller_class_nesting}::#{@controller_class_name_without_nesting}"

    model_class = class_name.constantize
    columns = model_class.content_columns
    columns = columns.select{|col| !%w(created_at updated_at).include?(col.name)} unless options[:add_timestamps]
    @attributes = columns.map{|column| Attribute.new(column)}

    (instance_variables - ["@option_parser"]).sort.map do |v|
      puts "#{v.inspect} => #{instance_variable_get(v).inspect}"
    end
    
  end

  def manifest
    puts "options => #{options.inspect}"
    
    
    recorded_session = record do |m|
      # m.class_collisions(controller_class_path, "#{controller_class_name}Controller", "#{controller_class_name}Helper")
      
      m.directory(File.join('app/controllers', controller_class_path))
      m.directory(File.join('app/helpers', controller_class_path))
      m.directory(File.join('app/views', controller_class_path, controller_file_name))
      m.directory(File.join('app/views/layouts', controller_class_path))
      m.directory(File.join('test/functional', controller_class_path))
      m.directory(File.join('test/unit', class_path))
      m.directory(File.join('public/stylesheets', class_path))
      
      
      m.template('controller.rb', 
        File.join('app/controllers', controller_class_path, "#{controller_file_name}_controller.rb"))
    
      m.template ('helper.rb',
        File.join('app/helpers', controller_class_path, "#{controller_file_name}_helper.rb"))

      m.template('functional_test.rb',
        File.join('test/functional', controller_class_path, "#{controller_file_name}_controller_test.rb"))
   
      if options[:generate_action_views]
        SCAFFOLD_VIEWS.each do |action|
          m.template(
            "view_#{action}.html.erb",
            File.join('app/views', controller_class_path, controller_file_name, "#{action}.html.erb"))
        end
      end
      SCAFFOLD_PARTIALS.each do |action|
        m.template("partial_#{action}.html.erb",
          File.join('app/views', controller_class_path, controller_file_name, "_#{action}.html.erb"))
      end
      
      # m.route_resources "#{controller_file_path.gsub('/', '_')}, :controller => #{controller_file_path}"
    end
  end
  
  protected
  
  SCAFFOLD_VIEWS = %w(index show new edit)
  SCAFFOLD_PARTIALS = %w(show new edit)
  
  def banner
    "Usage: #{$0} partial_scaffold ModelName ControllerName"
  end

    def add_options!(opt)
      opt.separator ''
      opt.separator 'Options:'
      opt.on("--add-timestamps",
             "Add timestamps to the view files for this model") { |v| options[:add_timestamps] = v }
      opt.on("--generate-action-views",
             "Generate action view files") {|v| options[:generate_action_views] = v}
    end

  
  
  
end

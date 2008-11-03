# require 'restful_authentication/rails_commands'
module Rails::Generator::Commands
  def self.map_resources_def(*resources)
    options = resources.extract_options!
    resource_list = resources.map { |r| r.to_sym.inspect }.join(', ')
    result = "\n  map.resources #{resource_list}"
    result << ", " << options.inspect.gsub(/^\{|\}$/, '') unless options.empty?
    result << "\n"
  end
  
  class Create
    def file_include?(relative_destination, sentense)
      path = destination_path(relative_destination)
      content = File.read(path)
      content.include?(sentense)
    end
    
    def route_resources(*resources)
      map_resources_def = Rails::Generator::Commands.map_resources_def(*resources)
      sentinel = 'ActionController::Routing::Routes.draw do |map|'
      
      stripped = map_resources_def.strip
      if file_include?('config/routes.rb', stripped)
        logger.identical stripped
        return
      end
      
      logger.route map_resources_def.strip
      unless options[:pretend]
        gsub_file 'config/routes.rb', /(#{Regexp.escape(sentinel)})/mi do |match|
          "#{match}#{map_resources_def}"
        end
      end
    end  
  end

  class Destroy
    def route_resources(*resources)
      resource_list = resources.map { |r| r.to_sym.inspect }.join(', ')
      look_for = Rails::Generator::Commands.map_resources_def(*resources)
      logger.route "map.resources #{resource_list}"
      gsub_file 'config/routes.rb', /(#{look_for})/mi, ''
    end
  end
end

class PartialScaffoldGenerator < Rails::Generator::NamedBase
  class Attribute < Rails::Generator::GeneratedAttribute

    attr_accessor :selectable_attr_type, :selectable_attr_base_name, :selectable_attr_enum
    
    def initialize(column, reflection = nil)
      @column = column
      @name, @type = column.name, column.type.to_sym
      @reflection = reflection
    end
    
    def field_type
      if @reflection
        return :belongs_to_field if @reflection.macro == :belongs_to
      elsif selectable_attr_type == :single
        return :select
      elsif selectable_attr_type == :multi
        return :check_box_group
      end
      super
    end
    
    def field
      if @reflection and @reflection.macro == :belongs_to
        controller_name = PartialScaffoldGenerator.model_name_to_controller_name[@reflection.class_name] || @reflection.class_name.tableize
        "belongs_to_field :#{@reflection.name.to_s}, :url => {:controller => '/#{controller_name}', :action => 'index'}"
      else
        "#{field_type} :#{name}"
      end
    end
    
    def data_in_functional_test
      if selectable_attr_type and selectable_attr_enum
        case selectable_attr_type
        when :single
          return selectable_attr_enum.entries.first.id.inspect
        when :multi
          return selectable_attr_enum.entries.map(&:id).inspect
        end
      end
      case type
      when :boolean           then 'true'
      when :integer           then '1' 
      when :float, :decimal   then '1.0'
      when :datetime          then 'DateTime.now'
      when :timestamp, :time  then 'Time.now'
      when :date              then 'Date.today'
      when :string            then "'some #{name}'"
      when :text              then "\"some #{name}\ninclude multilines\""
      else
        "'some #{name}'"
      end
    end
    
    def name_to_show
      case selectable_attr_type
      when :single
        "#{selectable_attr_base_name}_name"
      when :multi
        "#{selectable_attr_base_name}_names.join(', ')"
      else
        name
      end
    end
    
    def name_in_code
      case selectable_attr_type
      when :single
        "#{selectable_attr_base_name}_key"
      when :multi
        "#{selectable_attr_base_name}_keys"
      else
        name
      end
    end
  end
  
  def self.model_name_to_controller_name
    @model_name_to_controller_name ||= {}
  end
  
  default_options :generate_action_views => false, :add_timestamps => false
  
  attr_reader   :model_class,
                :controller_name,
                :controller_class_path,
                :controller_file_path,
                :controller_class_nesting,
                :controller_class_nesting_depth,
                :controller_class_name,
                :controller_singular_name,
                :controller_plural_name,
                :controller_file_name,
                :controller_association_names,
                :controller_resource_name_singularized,
                :controller_resource_name,
                :route_primary_key_name,
                :controller_reflections,
                :attrs_expression_for_test
  
  alias_method  :controller_table_name, :controller_plural_name

  def initialize(runtime_args, runtime_options = {})
    super(runtime_args, runtime_options)
    @model_class = class_name.constantize
    @controller_name = @args.shift || @name.pluralize
    
    PartialScaffoldGenerator.model_name_to_controller_name[class_name] = @controller_name
    
    associations_expr = @args.shift || ""
    @route_primary_key_name = @args.shift
    begin
      @associations = eval(associations_expr, TOPLEVEL_BINDING)
    rescue Exception => e
      raise "failed to eval: #{associations_expr} cause of #{e.message}"
    end

    base_name, @controller_class_path, @controller_file_path, @controller_class_nesting, @controller_class_nesting_depth = extract_modules(@controller_name)
    @controller_class_name_without_nesting, @controller_file_name, @controller_plural_name = inflect_names(base_name)
    @controller_singular_name = @controller_file_name.singularize

    @controller_class_name = @controller_class_nesting.empty? ?
    @controller_class_name_without_nesting :
      "#{@controller_class_nesting}::#{@controller_class_name_without_nesting}"
    
    path_parts = @controller_file_path.split('/')
    path_parts = path_parts[0..-2].map{|name| name.singularize} << path_parts[-1]
    @controller_resource_name = path_parts.join('_')
    @controller_resource_name_singularized = @controller_resource_name.singularize
    
    @controller_reflections = @model_class.reflections
    
    except_col_names = ['id', @route_primary_key_name]
    columns = @model_class.columns.select{|col| !except_col_names.include?(col.name) }
    columns = columns.select{|col| !%w(created_at updated_at).include?(col.name)} unless options[:add_timestamps]
    
    column_to_reflection = {}
    @controller_reflections.each do |name, reflection|
      column_to_reflection[reflection.primary_key_name.to_s] = reflection
    end
    
    ignore_selectable_attr = options[:ignore_selectable_attr] || !(Module.const_get(:SelectableAttr) rescue nil)
    @attributes = columns.map do |column| 
      attr = Attribute.new(column, column_to_reflection[column.name.to_s])
      unless ignore_selectable_attr
        attr.selectable_attr_type = @model_class.selectable_attr_type_for(column.name.to_s)
        if attr.selectable_attr_type
          attr.selectable_attr_base_name = @model_class.enum_base_name(column.name.to_s)
          attr.selectable_attr_enum = @model_class.enum_for(column.name.to_s)
        end
      end
      attr
    end
    
    @attrs_expression_for_test = test_attrs_expression(@attributes)
    
    @controller_association_names = nil
    if @associations.is_a?(Hash)
      @controller_association_names = @associations.keys
    elsif @associations.is_a?(Array)
      @controller_association_names = []
      @associations.each do |association|
        if association.is_a?(Hash)
          association.keys.each{|key| @controller_association_names << key }
        elsif association.is_a?(Array)
          association.each{|key| @controller_association_names << key }
        else
          @controller_association_names << association
        end
      end
    else
      @controller_association_names = [@associations]
    end
  rescue Exception => e
    puts e.message
    puts e.backtrace.join("\n  ")
    raise e
  end
  
  def test_attrs_expression(attributes)
    test_attr_names = nil
    begin
      record = @model_class.new({})
      record.valid?
      test_attr_names = record.errors.map{|attr, msg| attr.to_s}
    rescue
      test_attr_names = attributes.map{|attr|attr.name.to_s}
    end
    attributes_hash = Hash[*attributes.map{|a|[a.name.to_s, a]}.flatten]
    result = []
    test_attr_names.each do |attr_name|
      attr = attributes_hash[attr_name]
      result << ':%s => %s' % [attr_name, attr.data_in_functional_test]
    end
    '{%s}' % result.join(', ')
  rescue Exception => e
    puts e.message
    puts e.backtrace.join("\n  ")
    raise e
  end
  
  def manifest
    recorded_session = record do |m|
      begin
        m.directory('public/stylesheets')
        m.template('partial_scaffold.js', 'public/javascripts/partial_scaffold.js')
        m.template('verboseable.js', 'public/javascripts/verboseable.js')
        m.template('partial_scaffold.css', 'public/stylesheets/partial_scaffold.css')

        m.directory(File.join('app/controllers', controller_class_path))
        m.directory(File.join('app/helpers', controller_class_path))
        m.directory(File.join('app/views', controller_class_path, controller_file_name))
        m.directory(File.join('app/views/layouts', controller_class_path))
        m.directory(File.join('test/functional', controller_class_path))
        
        
        # m.class_collisions(controller_class_path, "#{controller_class_name}Controller", "#{controller_class_name}Helper")

        m.template('controller.rb', 
          File.join('app/controllers', controller_class_path, "#{controller_file_name}_controller.rb"))

        m.template('helper.rb',
          File.join('app/helpers', controller_class_path, "#{controller_file_name}_helper.rb"))

        m.template('functional_test.rb',
          File.join('test/functional', controller_class_path, "#{controller_file_name}_controller_test.rb"))

        m.template(
          "layout.html.erb",
          File.join('app/views/layouts', controller_class_path, "#{controller_file_name}.html.erb"))

        SCAFFOLD_VIEWS.each do |action|
          m.template(
            "view_#{action}.html.erb",
            File.join('app/views', controller_class_path, controller_file_name, "#{action}.html.erb"))
        end

        SCAFFOLD_PARTIALS.each do |action|
          m.template("partial_#{action}.html.erb",
            File.join('app/views', controller_class_path, controller_file_name, "_#{action}.html.erb"))
        end

        m.route_resources controller_resource_name, :controller => controller_file_path

        trace_associations(m, @model_class, @associations)
      rescue Exception => e
        puts e.message
        puts e.backtrace.join("\n  ")
        raise e
      end
    end
  end
  
  private
  
  def trace_associations(m, model_class, associations)
    case associations
    when Symbol, String
      reflection = model_class.reflections[associations.to_sym]
      m.dependency('partial_scaffold', 
        [reflection.class_name, "#{controller_name}/#{associations.to_s}", '', reflection.primary_key_name],
        options) # {:collision => :skip}.update(options) )
    when Hash
      associations.each do |key, value|
        reflection = model_class.reflections[key.to_sym]
        m.dependency('partial_scaffold', 
          [reflection.class_name, "#{controller_name}/#{key.to_s}", value.inspect, reflection.primary_key_name],
          options)
      end
    when Array
      associations.each do |association|
        trace_associations(m, model_class, association)
      end
    end
  end
  
  protected
  
  SCAFFOLD_VIEWS = %w(index show new edit)
  SCAFFOLD_PARTIALS = %w(index form show new edit)
  
  def banner
    "Usage: #{$0} partial_scaffold ModelName ControllerName \"association expression\" [primary_key_name]"
  end

  def add_options!(opt)
    opt.separator ''
    opt.separator 'Options:'
    opt.on("--add-timestamps",
      "Add timestamps to the view files for this model") { |v| options[:add_timestamps] = v }
    opt.on("--ignore-selectable-attr",
      "Don't generate field for selectable_attr plugin") { |v| options[:ignore_selectable_attr] = v }
  end
  
end

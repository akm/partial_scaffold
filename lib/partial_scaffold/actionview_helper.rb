module PartialScaffold
  module ActionviewHelper
    def uniq_tag_id(prefix)
      @indexes ||= {}
      @indexes[prefix] ||= 0
      @indexes[prefix] += 1
      "%s_%s_%04d" % [prefix, Time.now.to_f.to_s.gsub('.', ''), @indexes[prefix]]
    end
    
    def auth_token_param
      '%s=%s' % [request_forgery_protection_token, escape_javascript(form_authenticity_token)]
    end
    
    def cascade_name(object_name, options = {})
      options = {:cascade_suffix => "attrs"}.update(options || {})
      return object_name.to_s unless @object_name_path
      suffix ||= "attrs"
      key = "#{@object_name_path}[#{object_name}_#{suffix}]"
      @cacade_names ||= {}
      result = "#{key}[#{@cacade_names[key] ||= 0}]"
      @cacade_names[key] += 1
      result
    end
    
    def backup_instance_variable(variable_name, new_value)
      backup = instance_variable_get(variable_name)
      instance_variable_set(variable_name, new_value)
      begin
        yield if block_given?
      ensure
        instance_variable_set(variable_name, backup)
      end
    end
    
    def each_of_object_attr(object, attr_name, options = {}, &block)
      options = {
        :instance_variable_name => "@#{attr_name.to_s.singularize}"
      }.update(options || {})
      instance_variable_name = options[:instance_variable_name]
      object.send(attr_name).each do |attr|
        backup_instance_variable(instance_variable_name, attr) do
          yield(attr)
        end
      end
    end
    
    def reserve_cascade_form_name_path(object_name, options = {})
      @object_name_path_reservation = cascade_name(object_name, options)
      yield if block_given?
    end
    
    def cascade_form_for(object_name, *args, &block)
      options = args.extract_options!
      if !!@object_name_path_reservation
        options[:no_form_required] = true
        backup_instance_variable("@object_name_path", @object_name_path_reservation) do
          @object_name_path_reservation = nil
          cascade_form_for_without_updating_name_path(object_name, args, options, &block)
        end
      else
        options[:no_form_required] = !!@object_name_path
        backup_instance_variable("@object_name_path",
          params[:cascade_name] || cascade_name(object_name, options.delete(:cascade_suffix))) do
          cascade_form_for_without_updating_name_path(object_name, args, options, &block)
        end
      end
    end
    
    def cascade_form_for_without_updating_name_path(object_name, args, options, &block)
      object = args.first || instance_variable_get("@#{object_name}")
      update_builder_for_cascade(options)
      options[:no_form_required] ||= params[:no_form_required]
      if options[:no_form_required]
        fields_for(@object_name_path, object, options, &block)
      else
        args << options
        form_for(@object_name_path, object, *args, &block)
      end
    end
    
    def cascade_dispaly_field(object, options = {}, &block)
      update_builder_for_cascade(options, PartialScaffold::CascadeShowFieldsBuilder)
      fields_for("dummy", object, options, &block)
    end
    
    def update_builder_for_cascade(options, builder_class = nil)
      builder = (options[:builder] ||= (builder_class || PartialScaffold::CascadeFormBuilder))
      builder.extend(PartialScaffold::Cascadeable) unless builder.is_a?(PartialScaffold::Cascadeable)
    end

    attr_accessor :partial_scaffold_options
    
    def partial_scaffold
      @partial_scaffold ||= PartialScaffoldJs.new(self, :partial_scaffold)
    end
    
    class PartialScaffoldJs
      attr_accessor :options
      attr_accessor :js_var_name
      def initialize(template, js_var_name)
        @template = template
        @js_var_name = js_var_name.to_s
      end

      SCRIPT_TAG = "<script>\n//<![CDATA[\n%s\n//]]>\n</script>"
      
      def script(content)
        SCRIPT_TAG % content
      end
      
      def initialize_js(options = {})
        script("var #{@js_var_name} = new PartialScaffold('#{@template.auth_token_param}', #{options.to_json})")
      end
      
      def js_invocation(method_name, *args)
        script("#{@js_var_name}.#{method_name.to_s}(#{args.join(',')});")
      end
      
      def setup_actions(actions_id)
        js_invocation(:setup_base_pane, "$('#{actions_id}')")
      end
      
      def setup_parent_of_actions(actions_id)
        js_invocation(:setup_base_pane, "$('#{actions_id}').parentNode")
      end
      
      def setup_new(partial_base_id, ajax_form)
        js_invocation(:setup_new, "$('#{partial_base_id}')", !!ajax_form)
      end
      
      def setup_show(partial_base_id)
        js_invocation(:setup_show, "$('#{partial_base_id}')")
      end
      
      def setup_edit(partial_base_id)
        js_invocation(:setup_edit, "$('#{partial_base_id}')")
      end
    end
    
  end
end

module PartialScaffold
  module Cascadeable
    def self.included(base)
      base.module_eval do 
        alias_method_chain :fields_for, :cascade
      end
    end
    
    def fields_for_with_cascade(record_or_name_or_array, *args, &block)
      options = args.extract_options!
      builder = (options[:builder] ||= CascadeFormBuilder)
      builder.extend(Cascadeable) unless builder.is_a?(Cascadeable)
      args << options
      fields_for_without_cascade(record_or_name_or_array, *args, &block)
    end
    
    def cascade_name_base(name, suffix = "attrs")
      "#{self.object_name}[#{name}_#{suffix}]"
    end
    
    def each_of_object(attr_name, options = {}, &block)
      @template.each_of_object_attr(object, attr_name, options, &block)
    end
    
    def no_form_required?
      !!options[:no_form_required]
    end
    
    def ajax_form_required?
      return false if no_form_required?
      return @template.request.xhr?
    end
    
    def content_name(name)
      "#{name}_#{self.object_id}".gsub(/[-\.]/, '')
    end
    
    def content_for(name, content = nil, &block)
      @template.content_for(content_name(name), content, &block)
    end
    
    def yield(name)
      name = content_name(name)
      @template.instance_eval("yield('#{name}')")
    end
    
    BELOGNS_TO_MODEL_DISPLAYABLE_METHODS = %w(name caption label)
    
    def belongs_to_field(method, options)
      ref_model = object.class.reflections[method.to_sym]
      raise ArgumentError, "No reflection found '#{method.to_s}'" unless ref_model
      model = object.send(method)
      name_method = PartialScaffold.caption_method_for(model.class)
      partial_scaffold = @template.partial_scaffold
      link_id = @template.uniq_tag_id("belongs_to_field_link")
      result = @template.content_tag(:span, @template.send(:h, model.send(name_method)), :class => "belongs_to_field_name")
      hidden = hidden_field(ref_model.primary_key_name, :class => "belongs_to_field_hidden")
      unless hidden.blank?
        result << hidden << 
          @template.link_to("select", @template.url_for(options[:url]), :id => link_id, :class => "belongs_to_field_link") <<
          @template.javascript_tag("#{partial_scaffold.js_var_name}.setup_belongs_to_field($('#{link_id}'))")
      end
      "<span>#{result}</span>"
    end
    
  end
end

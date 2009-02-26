# -*- coding: utf-8 -*-
module PartialScaffold
  class ShowFieldsBuilder < ActionView::Helpers::FormBuilder
    def h(value)
      @template.send(:h, value)
    end
    
    def submit(value = "Save changes", options = {})
    end

    def label(method, text = nil, options = {})
      @template.content_tag(:b, text || method.to_s.humanize, options.stringify_keys)
    end

    def text_field(method, options = {})
      h(object.send(method))
    end

    def password_field(method, options = {})
      "********"
    end

    def hidden_field(method, options = {})
    end

    def file_field(method, options = {})
    end

    def text_area(method, options = {})
      value = object.send(method)
      value.blank? ? nil : value.split(/$/m).map{|line| h(line)}.join('<br/>')
    end

    def check_box(method, options = {}, checked_value = "1", unchecked_value = "0")
      object.send("#{method}?") ? '✓' : '□'
    end

    def radio_button(method, tag_value, options = {})
      object.send(method) == tag_value ? '◉' : '○'
    end

    ### form_options_helper.rb

    def select(method, choices = nil, options = {}, html_options = {})
      # for selectable_attr plugin
      if choices
        hash = Hash[*choices.flatten]
        h(hash[object.send(method)])
      elsif object.class.respond_to?(:enum_base_name)
        base_name = object.class.enum_base_name(method)
        if object.respond_to?("#{base_name}_names")
          object.send("#{base_name}_names").join(options[:separator] || ',')
        elsif object.respond_to?("#{base_name}_name")
          object.send("#{base_name}_name")
        else
          raise ArgumentError, "#{object.class.name} has no #{method}_name or #{method}_names"
        end
      else
        raise ArgumentError, "no choices and #{object.class.name} has no selectable_attr definition for #{method}"
      end
    end

    def collection_select(method, collection, value_method, text_method, options = {}, html_options = {})
      select(method, collection.map{|item| [item.send(text_method), item.send(value_method)]})
    end

    def country_select(method, priority_countries = nil, options = {}, html_options = {})
      h(object.send(method))
    end

    def time_zone_select(method, priority_zones = nil, options = {}, html_options = {})
      h(object.send(method))
    end

    def date_select(method, options = {}, html_options = {})
      h(object.send(method))
    end

    def time_select(method, options = {}, html_options = {})
      h(object.send(method))
    end

    def datetime_select(method, options = {}, html_options = {})
      h(object.send(method))
    end
    
    # for selectable_attr plugin
    if (Module.const_get(:SelectableAttr) rescue nil)
      
      class CheckBoxGroupBuilder < ::SelectableAttrRails::Helpers::CheckBoxGroupHelper::Builder
        def check_box
          @entry_hash[:select] ? '✓' : '□'
        end
      end
      
      def check_box_group(method, options = nil, &block)
        builder = CheckBoxGroupBuilder.new(object, object_name, method, options, @template)
        if block_given?
          yield(builder)
          return nil
        else
          result = ''
          builder.each do
            result << builder.check_box
            result << '&nbsp;'
            result << builder.label
            result << '&nbsp;'
          end
          return result
        end
      end
      
      class RadioButtonGroupBuilder < SelectableAttrRails::Helpers::RadioButtonGroupHelper::Builder
        def radio_button(options = nil)
          @entry_hash[:id] == @object.send(@method) ? '◉' : '○'
        end
      end
      
      def radio_button_group(method, options = nil, &block)
        builder = RadioButtonGroupBuilder.new(object, object_name, method, options, @template)
        if block_given?
          yield(builder)
          return nil
        else
          result = ''
          builder.each do
            result << builder.radio_button
            result << '&nbsp;'
            result << builder.label
            result << '&nbsp;'
          end
          return result
        end
      end
    end
    
  end  
end

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
      object.send(method) == tag_value ? '●' : '○'
    end

    ### form_options_helper.rb

    def select(method, choices, options = {}, html_options = {})
      hash = Hash[*choices.flatten]
      h(hash[object.send(method)])
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
  end  
end

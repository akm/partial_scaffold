module PartialScaffold
  module RenderPartialOnXhr
    def self.included(mod)
      mod.module_eval do 
        alias_method_chain :render, :partial_on_xhr
        alias_method_chain :redirect_to, :partial_on_xhr
      end
    end

    def redirect_to_with_partial_on_xhr(options = {}, response_status = {})
      return redirect_to_without_partial_on_xhr(options, response_status) unless request.xhr?
      action = options[:action]
      throw ArgumentError, "Action unspecified to render." unless action
      render_without_partial_on_xhr :partial => action
      if flash[:notice]
        response.body << update_flash_notice_js(flash[:notice])
        flash[:notice] = nil
      end
    end
    
    def update_flash_notice_js(msg, flash_notice_element_id = "flash_notice_area")
      msg_id = 'flash_notice_%d' % Time.now.to_i
      "<div id='#{msg_id}' style='display:none;'>" <<
        @template.send(:h, msg) <<
        "</div>\n" <<
        "<script>\n//<![CDATA[\n" << 
        "Element.update($('#{flash_notice_element_id}'), $('#{msg_id}').innerHTML);" << 
        "\n//]]>\n</script>\n"
    end
    
    def render_with_partial_on_xhr(options = nil, &block)
      if request.xhr? 
        if options.nil?
          options = {:partial => default_template_name}
        elsif options.key?(:action)
          options[:partial] = options.delete(:action)
        end
      end
      render_without_partial_on_xhr(options, &block)
    end
  end
end

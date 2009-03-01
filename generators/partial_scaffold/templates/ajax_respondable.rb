module AjaxRespondable
  def render_action_or_partial(template_name = action_name)
    render((request.xhr? ? :partial : :action) => template_name)
  end
  
  def redirect_to_or_render(options = {})
    return redirect_to(options) unless request.xhr?
    action = options[:action]
    throw ArgumentError, "Action unspecified to render." unless action
    render :partial => action
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
end

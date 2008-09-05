module PartialScaffold
  module RenderPartialOnXhr
    def self.included(mod)
      mod.module_eval do 
        alias_method_chain :render, :partial_on_xhr
      end
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

  module AjaxRedirectable
    def self.included(mod)
      mod.module_eval do 
        alias_method_chain :redirect_to, :ajax_redirectable
      end
    end
    
    def redirect_to_with_ajax_redirectable(options = {}, response_status = {}) #:doc:
      if request.xhr?
        return render(:text => nil) if params[:redirection] == 'render_null'
        case options
        when String
          connector = (options =~ /\?/) ? "&" : "?"
          options << connector << "ajax_redirection=true"
        when :back
        when Hash
          if params[:redirection]
            options[:action] = params[:redirection]
          end
        else
          if params[:redirection]
            options = {:action => params[:redirection], :id => options.id}
          end
        end
      end
      redirect_to_without_ajax_redirectable(options, response_status)
    end
    
    module Request
      def self.included(mod)
        mod.module_eval do 
          alias_method_chain :xml_http_request?, :ajax_redirection
          alias_method :xhr?, :xml_http_request?
        end
      end
      
      def xml_http_request_with_ajax_redirection?
        xml_http_request_without_ajax_redirection? or 
          (@query_parameters["ajax_redirection"] == "true")
      end
    end
  end
end

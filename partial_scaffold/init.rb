require "partial_scaffold"
require "attrs_acceptable"
::ActionController::AbstractRequest.send(:include, ::PartialScaffold::AjaxRedirectable::Request)
::ActiveRecord::Base.send(:include, AttrsAcceptable)

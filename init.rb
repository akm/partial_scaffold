require "partial_scaffold"
require "partial_scaffold/attrs_acceptable"
# ::ActionController::AbstractRequest.send(:include, ::PartialScaffold::AjaxRedirectable::Request)
::ActiveRecord::Base.send(:include, PartialScaffold::AttrsAcceptable)

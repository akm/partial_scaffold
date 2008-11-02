module PartialScaffold
  class CascadeFormBuilder < ActionView::Helpers::FormBuilder
    include Cascadeable
  end
end

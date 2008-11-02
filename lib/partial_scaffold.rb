module PartialScaffold
  VERSION = "0.1.0"
  
  class << self
    def caption_method_candidates
      @caption_method_candidates ||= [/display\_name/, /caption/, /name/, /title/, /label/]
    end
    
    def caption_method_candidates=(value)
      @caption_method_candidates = value
    end
    
    def caption_method_for(klass)
      @caption_methods ||= {}
      result = @caption_methods[klass]
      unless result
        if klass.respond_to?(:content_columns)
          column = klass.content_columns.detect do |col|
            caption_method_candidates.any?{|candidate| candidate =~ col.name}
          end
          result = column ? column.name : :inspect
        else
          result = klass.instance_methods.detect do |method|
            caption_method_candidates.any?{|candidate| candidate =~ method}
          end
          result ||= :inspect
        end
        @caption_methods[klass] = result
      end
      result
    end
    
    def set_caption_method(klass, method)
      @caption_methods ||= {}
      @caption_methods[klass] = method
    end
  end
end

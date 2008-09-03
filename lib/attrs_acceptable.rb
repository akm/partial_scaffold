module AttrsAcceptable
  
  def self.included(mod)
    mod.extend(ClassMethods)
    mod.instance_eval do 
      alias :has_one_without_attr_acceptable :has_one
      alias :has_one :has_one_with_attr_acceptable
      alias :has_many_without_attr_acceptable :has_many
      alias :has_many :has_many_with_attr_acceptable
    end
  end
  
  module ClassMethods
    private
    def acceptable_options!(original_options)
      acceptable = (original_options || {}).delete(:acceptable) || {}
      acceptable = {:suffix => acceptable.to_s} unless acceptable.is_a?(Hash)
      acceptable[:class_name] = original_options[:class_name]
      acceptable
    end
    
    public
    def has_many_with_attr_acceptable(association_id, options = {})
      acceptable_options = acceptable_options!(options)
      result = has_many_without_attr_acceptable(association_id, options)
      has_many_acceptable(association_id, acceptable_options)
      result
    end
    
    def has_one_with_attr_acceptable(association_id, options = {})
      acceptable_options = acceptable_options!(options)
      result = has_one_without_attr_acceptable(association_id, options)
      has_one_acceptable(association_id, acceptable_options)
      result
    end
    
    def has_one_acceptable(has_one_name, options = {:suffix => "attrs"})
      has_one_name = has_one_name.to_s
      attr_name = "#{has_one_name}_#{(options[:suffix] || "attrs").to_s}"
      class_name = options[:class_name] || has_one_name.classify
      self.module_eval(<<-"EOS")
        attr_accessor :#{attr_name}
        before_validation_on_create :instanciate_#{has_one_name}

        def instanciate_#{has_one_name}
          self.#{has_one_name} = #{class_name}.new(#{attr_name}) if #{attr_name}
        end

        def validate_with_#{has_one_name}
          validate_without_#{has_one_name} and self.#{has_one_name}.valid?
        end

        alias_method :validate_without_#{has_one_name}, :validate
        alias_method :validate, :validate_with_#{has_one_name}
      EOS
    end
      
    def has_many_acceptable(has_many_name, options = {:suffix => "attrs"})
      has_many_name = has_many_name.to_s
      attr_name = "#{has_many_name}_#{(options[:suffix] || "attrs").to_s}"
      class_name = options[:class_name] || has_many_name.classify
      self.module_eval(<<-"EOS")
        attr_accessor :#{attr_name}
        before_validation_on_create :instanciate_#{has_many_name}

        def instanciate_#{has_many_name}
          #{has_many_name} << #{attr_name}.map{|attrs| #{class_name}.new(attrs)} if #{attr_name}
        end

        def validate_with_#{has_many_name}
          result = validate_without_#{has_many_name}
          return result && #{has_many_name}.all?{|record| record.valid?}
        end

        alias_method :validate_without_#{has_many_name}, :validate
        alias_method :validate, :validate_with_#{has_many_name}
      EOS
    end
  end
end

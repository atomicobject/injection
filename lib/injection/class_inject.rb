module Injection
  module ClassInject
    extend ActiveSupport::Concern
  
    module Initialize #:nodoc:
      extend ActiveSupport::Concern
    
      def initialize(*args)
        if args.empty?
          raise 'No context file loaded' if Injection.context.is_a?(Hash)
          constructor_args = self.class.constructor_keys.inject({}) do |memo, key|
            memo[key] = Injection.context[key]
            memo
          end
          super(constructor_args)
        else
          super
        end
      end
    end
  
    module ClassMethods
      #
      # Specify which components should be injected into this observer as the 
      # list of <tt>keys</tt> to look them up from the DI context.
      #
      def inject(*keys)
        constructor_args = if keys.last.is_a?(Hash)
          keys[0..-2] + [{:super => []}.merge(keys.last)]
        else
          keys + [:super => []]
        end
        constructor *constructor_args
        include Initialize
      end
    end
  end
end
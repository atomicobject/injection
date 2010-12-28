module Injection
  module ObserverExtension
    extend ActiveSupport::Concern
      
    module ClassMethods
      #
      # Specify what events the observer is interested in after an activerecord object has
      # performed an operation by passing in a <tt>symbol</tt> and a <tt>block</tt>.
      def after(observation, &block)
        build_methods(:after, observation, &block)
      end
      
      #
      # Specify what events the observer is interested in before an activerecord object has
      # performed an operation by passing in a <tt>symbol</tt> and a <tt>block</tt>.
      def before(observation, &block)
        build_methods(:before, observation, &block)
      end
      
      #
      # Specify what events the observer is interested in before and after an activerecord object has
      # performed an operation by passing in a <tt>symbol</tt> and a <tt>block</tt> that yields.
      def around(observation, &block)
        build_methods(:around, observation, &block)
      end
      
      private
      
      def build_methods(before_after, observation, &block)
        mname = build_method_name(before_after, observation)
        validate_observation! mname
        define_method(mname, &block)
      end
      
      def build_method_name(before_after, observation)
        "#{before_after}_#{observation}"
      end
      
      def validate_observation!(observation)
        raise "#{observation} is not an observable action" unless ActiveRecord::Callbacks::CALLBACKS.include? observation.to_sym
      end
    end
  end
end
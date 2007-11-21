module Injection
  module ObserverExtension
    def self.included(base)
      base.extend ClassMethods
      base.send :include, InstanceMethods
    end
    
    module InstanceMethods #:nodoc:
      #
      # Only observe active record objects if the instance is the singleton accessed
      # via the instance method.
      #
      def inject_setup(*args) #:nodoc:
        observer_initialization if args.empty?        
      end
    end
  
    module ClassMethods
      #
      # Specify what events the observer is interested in after an activerecord object has
      # performed an operation by passing in a <tt>symbol</tt> and a <tt>block</tt>. An
      # optional condition can be passed in for validation observations passing in a hash 
      # with the key <tt>:on</tt> and value(s) that represents what action it is interested in.
      #
      def after(observation, opts={}, &block)
        build_methods(:after, observation, opts, &block)
      end
    
      #
      # Specify what events the observer is interested in before an activerecord object has
      # performed an operation by passing in a <tt>symbol</tt> and a <tt>block</tt>. An
      # optional condition can be passed in for validation observations passing in a hash 
      # with the key <tt>:on</tt> and a value(s) that represents what action it is interested in.
      #
      def before(observation, opts={}, &block)
        build_methods(:before, observation, opts, &block)
      end
      
      #
      # Saves original observer initialize method unless it has already been saved.
      #
      def inject_setup(*keys) #:nodoc:
        alias_method :observer_initialization, :initialize unless private_method_defined?(:observer_initialization)
      end
                  
      private
    
      def build_methods(before_after, observation, opts, &block)
        if opts[:on].is_a? Array
          opts[:on].each do |on|
            mname = build_method_name(before_after, observation, on)
            validate_observation! mname
            define_method(mname, &block)
          end
        else
          mname = build_method_name(before_after, observation, opts[:on])
          validate_observation! mname
          define_method(mname, &block)
        end
      end
    
      def build_method_name(before_after, observation, on=nil)
        mname = "#{before_after}_#{observation}"
        mname = mname + "_on_#{on}" if on
        mname
      end
    
      def validate_observation!(observation)
        raise "#{observation} is not an observable action" unless ActiveRecord::Callbacks::CALLBACKS.include? observation
      end
    end
  end
end
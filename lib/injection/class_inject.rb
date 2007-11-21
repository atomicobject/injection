module Injection
  def self.included(base)
    base.extend ClassMethods
  end
  
  module ClassMethods
    #
		# Specify which components should be injected into this observer as the 
		# list of <tt>keys</tt> to look them up from the DI context.
		#
    def inject(*keys)
      inject_setup(*keys) if respond_to?(:inject_setup)
			constructor(*keys)
			define_method(:initialize_with_inject) do |*args|
			  inject_setup(*args) if respond_to?(:inject_setup)
			  clazz = self.class
			  clazz.constructor(*[]) if clazz.constructor_keys.nil?
			  if args.empty?
			    raise 'No context file loaded' if Injection.context.is_a?(Hash)
			    constructor_args = {}
					clazz.constructor_keys.each do |key|
					  constructor_args[key] = Injection.context[key]
					end
					initialize_without_inject(constructor_args)
				else
					initialize_without_inject(*args)
				end
			end
			alias_method :initialize_without_inject, :initialize
			alias_method :initialize, :initialize_with_inject
		end
  end
end
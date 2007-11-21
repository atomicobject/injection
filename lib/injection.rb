require 'diy'
require 'constructor'
require 'injection/class_inject'
require 'injection/observer_inject'

# === Accessing Objects in the Context
#
# Provides access to the context loaded from <tt>config/objects.yml</tt> which 
# can be used to look up individual components.
#
# config/objects.yml:
#   ---
#   foo:
#   bar:
# 
# lib/foo.rb:
#   class Foo
#     ...
#   end
#
#   Inject.context[:foo]   #=> #<Foo:0x81eb0>
#
module Injection
  VERSION = "1.5.1"
  # Accessor for the context loaded from <tt>config/objects.yml</tt>
	def self.context
		@@context
	end

	# Initializes the context from the definition stored in the given file.
	def self.init_context(context_file)
		if File.exists?(context_file)
			the_context = DIY::Context.from_file(context_file)
			self.context = the_context
		else
			self.context = {}
		end
	end

	protected

	@@context = {}
	def self.context=(new_context) #:nodoc:
		@@context = new_context
	end
end

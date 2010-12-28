require 'diy'
require 'constructor'
require 'injection/railtie'
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
  @@context = {}
  @@extra_inputs = {}

  # Accessor for the context loaded from <tt>config/objects.yml</tt>
  def self.context
    @@context
  end
  
  def self.context_file=(path)
    @@context_file = path
  end
  
  def self.extra_inputs=(hash)
    @@extra_inputs = hash
  end

  def self.reset_context
    @@context = DIY::Context.from_file(@@context_file, @@extra_inputs) if File.exists?(@@context_file)
  end
end


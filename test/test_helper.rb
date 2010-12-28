require "rubygems"
require "bundler/setup"
require 'test/unit'


require 'injection'
require 'rails/all'

module TestInjection
  class Application < Rails::Application
  end
end
TestInjection::Application.initialize!

class Test::Unit::TestCase
  def path_to(path)
    File.expand_path(File.dirname(__FILE__)) + '/' + path
  end
  
  def set_context(path)
    Injection.init_context path_to(path)
  end

  def context
    Injection.context
  end
end

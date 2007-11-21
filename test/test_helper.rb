ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + '/../../../../config/environment')
require 'test_help'

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

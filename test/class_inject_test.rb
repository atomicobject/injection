here = File.expand_path(File.dirname(__FILE__))
require here + '/test_helper'
$:.unshift here

class ClassInjectTest < Test::Unit::TestCase

  def test_normal_object_with_valid_context
		set_context 'objects.yml'

		foo, bar = 'foo', 'bar'
		controller = NormalController.new
		assert_not_nil controller
  end
	
	def test_injected_object_from_context
		set_context 'objects.yml'

		controller = InjectedController.new
		assert_not_nil controller
		assert_same context[:foo], controller.foo
		assert_same context[:bar], controller.bar
	end

	def test_injected_object_given_params
		set_context 'objects.yml'

		foo, bar = 'foo', 'bar'
		controller = InjectedController.new :foo => foo, :bar => bar
		assert_not_nil controller
		assert_same foo, controller.foo
		assert_same bar, controller.bar
	end

  def test_poorly_injected_object_from_context_component_not_found
		set_context 'objects.yml'

		err = assert_raise DIY::ConstructionError do
			PoorlyInjectedController.new
		end
		assert_match(/qux/i, err.message) 
  end

  def test_poorly_injected_object_given_params
		set_context 'objects.yml'

		foo, bar, qux = 'foo', 'bar', 'qux'
		controller = PoorlyInjectedController.new :foo => foo, :bar => bar, :qux => qux
		assert_same foo, controller.foo
		assert_same bar, controller.bar
		assert_same qux, controller.qux
  end

  def test_injected_object_given_partial_params
		set_context 'objects.yml'

		err = assert_raise ConstructorArgumentError do
		  InjectedController.new :foo => 'foo'
		end
		assert_match(/bar/i, err.message) 
  end

  def test_injected_object_given_params_non_existent_context_file
		set_context 'not a file path'

		foo, bar = 'foo', 'bar'
		controller = InjectedController.new :foo => foo, :bar => bar
		assert_not_nil controller
		assert_same foo, controller.foo
		assert_same bar, controller.bar
  end

  def test_normal_object_non_existent_context_file
		set_context 'not a file path'

		foo, bar = 'foo', 'bar'
		controller = NormalController.new
		assert_not_nil controller
  end
  
  def test_that_object_inheritance_works_using_inject
    set_context 'objects.yml'
    
    assert_kind_of(TheFooClass, GalaxyController.new.foo)
    
    controller = SpiralGalaxyController.new
    injected_controller = SpiralGalaxyController.new(:foo => "foo", :bar => "bar")
    assert_equal GalaxyController, SpiralGalaxyController.superclass
    assert_kind_of(TheFooClass, controller.foo)
    assert_kind_of(Bar, controller.bar)
    assert_equal ["foo", "bar"], [injected_controller.foo, injected_controller.bar]
    
    controller = MilkyWayGalaxyController.new
    injected_controller = MilkyWayGalaxyController.new(:foo => "foo", :bar => "bar", :foo_piece_two => "foo2")
    assert_equal SpiralGalaxyController, MilkyWayGalaxyController.superclass
    assert_kind_of(TheFooClass, controller.foo)
    assert_kind_of(Bar, controller.bar)
    assert_kind_of(FooPieceTwo, controller.foo_piece_two)
    assert_equal ["foo", "bar", "foo2"], [injected_controller.foo, injected_controller.bar, injected_controller.foo_piece_two]    
    
    controller = FutureMilkyWayGalaxyController.new
    injected_controller = FutureMilkyWayGalaxyController.new(:foo => "foo", :bar => "bar", :foo_piece_two => "foo2")
    assert_equal MilkyWayGalaxyController, FutureMilkyWayGalaxyController.superclass
    assert_kind_of(TheFooClass, controller.foo)
    assert_kind_of(Bar, controller.bar)
    assert_kind_of(FooPieceTwo, controller.foo_piece_two)
    assert_equal ["foo", "bar", "foo2"], [injected_controller.foo, injected_controller.bar, injected_controller.foo_piece_two]    
  end
  
  def test_calls_inject_setup_on_instance_and_class_level
    assert_equal [], InjectSetupFixture.saved_keys, "should have been an empty key set"
    assert !InjectSetupFixture.called, "should not have been called"
    InjectSetupFixture.inject :foo
    assert_equal [:foo], InjectSetupFixture.saved_keys, "wrong keys"
    assert_equal true, InjectSetupFixture.called, "should have called inject_setup"
    
    instance = InjectSetupFixture.new(:foo => "bar")
    assert_equal [{:foo => "bar"}], instance.saved_args
    assert_equal true, instance.called
  end
end

class InjectSetupFixture
  include Injection
  attr_reader :saved_args, :called
  
  @@saved_keys = []
  @@called = false
  
  def self.saved_keys; @@saved_keys end
  def self.called; @@called end
  
  def self.inject_setup(*keys)
    @@saved_keys = keys
    @@called = true
  end
  
  def inject_setup(*args)
    @saved_args = args
    @called = true
  end
end

class InjectedController < ActionController::Base
	inject :foo, :bar
	attr_reader :foo, :bar
end

class PoorlyInjectedController < ActionController::Base
	inject :foo, :bar, :qux
	attr_reader :foo, :bar, :qux
end

class NormalController < ActionController::Base
end

class Bar
end

class TheFooClass
	constructor :foo_piece_one, :foo_piece_two
end

class FooPieceOne
end

class FooPieceTwo
end

class GalaxyController < ActionController::Base
  inject :foo
  attr_accessor :foo
end

class SpiralGalaxyController < GalaxyController
  inject :bar
  attr_accessor :bar
end

class MilkyWayGalaxyController < SpiralGalaxyController
  inject :foo_piece_two
  attr_accessor :foo_piece_two
end

class FutureMilkyWayGalaxyController < MilkyWayGalaxyController; end
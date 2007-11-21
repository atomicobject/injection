here = File.expand_path(File.dirname(__FILE__))
require here + '/test_helper'
$:.unshift here

class ObserverInjectionTest < Test::Unit::TestCase
  def setup
    @target = MyObserver.instance
    @observations = []
  end
  
  def test_should_be_able_to_define_observations_in_a_declaritive_way
    ActiveRecord::Callbacks::CALLBACKS.sort.each do |callback|
      @target.update(callback, @observations)
    end
    
    assert_equal ActiveRecord::Callbacks::CALLBACKS.size, @observations.size
    verify_after_observations
    verify_before_observations
    assert_equal 0, @observations.size    
  end
  
  def test_should_be_able_to_define_multiple_on_conditionals_for_validation_observations
    number_of_after_observations = 0
    number_of_before_observations = 0
    saved_record = nil
    
    EmptyObserver.class_eval do
      after :validation, :on => [:create, :update] do |record|
        saved_record = record
        number_of_after_observations = number_of_after_observations + 1
      end
      
      before :validation, :on => [:create, :update] do |record|
        saved_record = record
        number_of_before_observations = number_of_before_observations + 1
      end
    end
    
    observer = EmptyObserver.instance
    
    observer.update(:after_validation_on_create, "foo")
    assert_equal "foo", saved_record, "wrong record"
    observer.update(:after_validation_on_create, "bar")
    assert_equal "bar", saved_record, "wrong record"
    
    assert_equal 2, number_of_after_observations
    
    observer.update(:before_validation_on_update, "foo2")
    assert_equal "foo2", saved_record, "wrong record"
    observer.update(:before_validation_on_create, "bar2")
    assert_equal "bar2", saved_record, "wrong record"
    
    assert_equal 2, number_of_before_observations
  end
  
  def test_should_raise_an_error_if_invalid_observations_are_given
    assert_error(RuntimeError, "after_foo is not an observable action") do
      MyObserver.class_eval do
        after :foo do
        end
      end
    end
    
    assert_error(RuntimeError, "before_bar is not an observable action") do
      MyObserver.class_eval do 
        before :bar do
        end
      end
    end
    
    assert_error(RuntimeError, "before_bar_on_nothing is not an observable action") do
      MyObserver.class_eval do 
        before :bar, :on => :nothing do
        end
      end
    end
    
    assert_error(RuntimeError, "after_validation_on_nothing is not an observable action") do
      MyObserver.class_eval do 
        after :validation, :on => :nothing do
        end
      end
    end
  end
  
  def test_should_be_able_to_inject_objects_using_the_private_new_method    
    observer = InjectedRecordObserver.send(:new, :my_object => "injected object", :another_object => "hello")
    assert_not_equal observer, InjectedRecordObserver.send(:new, :my_object => "injected object", :another_object => "hello")
    
    assert_equal 0, InjectedRecord.count_observers
    assert_equal 0, SubClassedInjectedRecord.count_observers
    
    assert_equal "injected object", observer.my_object
    assert_equal "hello", observer.another_object
  end
  
  def test_should_inject_from_context_when_calling_instance
    set_context 'objects.yml'
    
    observer = InjectedRecordObserver.instance
    assert_same observer, InjectedRecordObserver.instance
    verify_record_has_observer(observer, InjectedRecord)
    verify_record_has_observer(observer, SubClassedInjectedRecord)
    verify_record_has_observer(observer, DistantAncestorOfInjectedRecord)
    
    assert_kind_of MyObject, observer.my_object, "should be a MyObject instance"
    assert_kind_of AnotherObject, observer.another_object, "should be AnotherObject instance"
  end
  
  def test_that_inheritance_works_as_expected
    set_context 'objects.yml'
    
    observer = BigBangObserver.instance
    assert_kind_of(MyObject, observer.my_object)
    verify_record_has_observer(observer, BigBang)
    
    observer = GalaxyObserver.instance
    assert_kind_of(MyObject, observer.my_object)
    assert_kind_of(AnotherObject, observer.another_object)
    verify_record_has_observer(observer, Galaxy)
    
    observer = SolarSystemObserver.instance
    assert_kind_of(MyObject, observer.my_object)
    assert_kind_of(AnotherObject, observer.another_object)
    verify_record_has_observer(observer, SolarSystem)
  end
  
  #
  # HELPERS
  #

  def verify_record_has_observer(observer, record)
    assert_equal 1, record.count_observers
    observers = record.add_observer(observer)
    assert_same observer, observers.shift
    assert_same observer, observers.shift
  end
  
  def verify_after_observations
    verify_observation(@observations.shift, :when => "after", :operation => "create")
    verify_observation(@observations.shift, :when => "after", :operation => "destroy")
    verify_observation(@observations.shift, :when => "after", :operation => "find")
    verify_observation(@observations.shift, :when => "after", :operation => "initialize")
    verify_observation(@observations.shift, :when => "after", :operation => "save")
    verify_observation(@observations.shift, :when => "after", :operation => "update")
    verify_observation(@observations.shift, :when => "after", :operation => "validation")
    verify_observation(@observations.shift, :when => "after", :operation => "validation", :on => "create")
    verify_observation(@observations.shift, :when => "after", :operation => "validation", :on => "update")
  end
  
  def verify_before_observations
    verify_observation(@observations.shift, :when => "before", :operation => "create")
    verify_observation(@observations.shift, :when => "before", :operation => "destroy")
    verify_observation(@observations.shift, :when => "before", :operation => "save")
    verify_observation(@observations.shift, :when => "before", :operation => "update")
    verify_observation(@observations.shift, :when => "before", :operation => "validation")
    verify_observation(@observations.shift, :when => "before", :operation => "validation", :on => "create")
    verify_observation(@observations.shift, :when => "before", :operation => "validation", :on => "update")    
  end
  
  def verify_observation(actual, expected)
    assert_equal expected, actual, "observations were not the same"
  end
  
  def assert_error(err_type,*patterns,&block)
    assert_not_nil block, "assert_error requires a block"
    assert((err_type and err_type.kind_of?(Class)), "First argument to assert_error has to be an error type")
    err = assert_raise(err_type) do
      block.call
    end
    patterns.each do |pattern|
      case pattern
      when Regexp
        assert_match(pattern, err.message) 
      else
        assert_equal pattern, err.message
      end
    end
  end
end

class ObservableRecord < ActiveRecord::Base; end
class MyObserver < ActiveRecord::Observer
  observe ObservableRecord
  
  ActiveRecord::Callbacks::CALLBACKS.each do |callback|
    actions = callback.split("_")
    if actions.size == 2
      case actions[0]
        when "after"
          after actions[1] do |record|
            record << {:when => "after", :operation => actions[1]}
          end
        when "before"
          before actions[1] do |record|
            record << {:when => "before", :operation => actions[1]}
          end
      end
    elsif actions.size == 4
      case actions[0]
        when "after"
          after actions[1], :on => actions[3] do |record|
            record << {:when => "after", :operation => actions[1], :on => actions[3]}
          end
        when "before"
          before actions[1], :on => actions[3] do |record|
            record << {:when => "before", :operation => actions[1], :on => actions[3]}
          end
      end
    end
  end
end

class EmptyObserver < ActiveRecord::Observer
  observe ObservableRecord
end

class InjectedRecord < ActiveRecord::Base; end
class SubClassedInjectedRecord < InjectedRecord; end
class DistantAncestorOfInjectedRecord < SubClassedInjectedRecord; end
class MyObject; end
class AnotherObject; end
class InjectedRecordObserver < ActiveRecord::Observer
  inject :my_object, :another_object
  attr_reader :my_object, :another_object
end

# Bad inheritance hierarchy, but whatever
class BigBang < ActiveRecord::Base; end
class BigBangObserver < ActiveRecord::Observer 
  inject :my_object 
  attr_accessor :my_object 
end

class Galaxy < ActiveRecord::Base; end
class GalaxyObserver < BigBangObserver 
  inject :another_object
  attr_accessor :another_object, :my_object
end

class SolarSystem < ActiveRecord::Base; end
class SolarSystemObserver < GalaxyObserver; attr_accessor :another_object, :my_object end
  

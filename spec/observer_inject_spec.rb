require 'spec_helper'

describe Injection::ObserverExtension do
  subject { MyObserver.instance }
  before do
    @observations = []
  end

  it "should be able to define observations in a declaritive way" do
    ActiveRecord::Callbacks::CALLBACKS.sort {|a,b| a.to_s <=> b.to_s}.each do |callback|
      subject.update(callback, @observations)
    end
    
    @observations.size.should == ActiveRecord::Callbacks::CALLBACKS.size
    verify_after_observations
    verify_before_observations
    @observations.should be_empty
  end
  
  it "should be able to define multiple on conditionals for validation observations" do
    number_of_after_observations = 0
    number_of_before_observations = 0
    saved_record = nil
    
    EmptyObserver.class_eval do
      after :validation do |record|
        saved_record = record
        number_of_after_observations = number_of_after_observations + 1
      end
      
      before :validation do |record|
        saved_record = record
        number_of_before_observations = number_of_before_observations + 1
      end
    end
    
    observer = EmptyObserver.instance
    
    observer.update(:after_validation, "foo")
    assert_equal "foo", saved_record, "wrong record"
    
    observer.update(:after_validation, "bar")
    assert_equal "bar", saved_record, "wrong record"
    
    assert_equal 2, number_of_after_observations
    
    observer.update(:before_validation, "foo2")
    assert_equal "foo2", saved_record, "wrong record"
    observer.update(:before_validation, "bar2")
    assert_equal "bar2", saved_record, "wrong record"
    
    assert_equal 2, number_of_before_observations
  end
  
  it "should raise an error if invalid observations are given" do
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
  end
  
  it "should inject from context when calling instance" do
    observer = InjectedRecordObserver.instance
    assert_same observer, InjectedRecordObserver.instance
    verify_record_has_observer(observer, InjectedRecord)
    verify_record_has_observer(observer, SubClassedInjectedRecord)
    verify_record_has_observer(observer, DistantAncestorOfInjectedRecord)
    
    assert_kind_of MyObject, observer.my_object, "should be a MyObject instance"
    assert_kind_of AnotherObject, observer.another_object, "should be AnotherObject instance"
  end
  
  it "supports inheritance" do
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
  
  it "runs its own example" do
    monkey = double(:monkey)
    target = BananaObserver.send(:new, :monkey => monkey)
    banana = Banana.new

    monkey.should_receive(:peels).with(banana)
    target.update(:before_create, banana)
  end
  
  #
  # HELPERS
  #

  def verify_record_has_observer(observer, record)
    record.count_observers.should > 0
    assert_equal 1, record.count_observers
    observers = record.add_observer(observer)
    assert_same observer, observers.shift
    assert_same observer, observers.shift
  end
  
  def verify_after_observations
    verify_observation(@observations.shift, :when => "after", :operation => "commit")
    verify_observation(@observations.shift, :when => "after", :operation => "create")
    verify_observation(@observations.shift, :when => "after", :operation => "destroy")
    verify_observation(@observations.shift, :when => "after", :operation => "find")
    verify_observation(@observations.shift, :when => "after", :operation => "initialize")
    verify_observation(@observations.shift, :when => "after", :operation => "rollback")
    verify_observation(@observations.shift, :when => "after", :operation => "save")
    verify_observation(@observations.shift, :when => "after", :operation => "touch")
    verify_observation(@observations.shift, :when => "after", :operation => "update")
    verify_observation(@observations.shift, :when => "after", :operation => "validation")

    verify_observation(@observations.shift, :when => "around", :operation => "create")
    verify_observation(@observations.shift, :when => "around", :operation => "destroy")
    verify_observation(@observations.shift, :when => "around", :operation => "save")
    verify_observation(@observations.shift, :when => "around", :operation => "update")

  end
  
  def verify_before_observations
    verify_observation(@observations.shift, :when => "before", :operation => "create")
    verify_observation(@observations.shift, :when => "before", :operation => "destroy")
    verify_observation(@observations.shift, :when => "before", :operation => "save")
    verify_observation(@observations.shift, :when => "before", :operation => "update")
    verify_observation(@observations.shift, :when => "before", :operation => "validation")
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
    actions = callback.to_s.split("_")
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
        when "around"
          around actions[1] do |record|
            record << {:when => "around", :operation => actions[1]}
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
class SolarSystemObserver < GalaxyObserver
end

class Banana < ActiveRecord::Base; end
class BananaObserver < ActiveRecord::Observer
  inject :monkey

  before :create do |banana|
    @monkey.peels(banana)
  end
end

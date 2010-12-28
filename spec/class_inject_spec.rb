require 'spec_helper'

class NormalController < ActionController::Base
end

class InjectedController < ActionController::Base
  inject :foo, :bar
  attr_reader :foo, :bar
end

class PoorlyInjectedController < ActionController::Base
  inject :foo, :bar, :qux
  attr_reader :foo, :bar, :qux
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

class FutureMilkyWayGalaxyController < MilkyWayGalaxyController; 
  constructor
end

class CommercialController < ActionController::Base
  inject :old, :readers => true
end

describe 'class inject' do
  before do
    # Instantiate a controller to kick start Rails into loading Injection
    InjectedController.new 
  end
  
  it "does not mess up construction of a normal controller" do
    controller = NormalController.new
    controller.should_not be_nil
  end
  
  it 'injects objects from context' do
    controller = InjectedController.new
    controller.should_not be_nil
    controller.foo.should equal(injection_context[:foo])
    controller.bar.should equal(injection_context[:bar])
  end
  
  it 'uses the params in injected object' do
    foo, bar = 'foo', 'bar'
    controller = InjectedController.new :foo => foo, :bar => bar
    controller.should_not be_nil
    controller.foo.should equal(foo)
    controller.bar.should equal(bar)
  end
  
  it "raises an error for a poorly injected object when a component is not found" do
    lambda { PoorlyInjectedController.new }.should raise_error(DIY::ConstructionError, /qux/i)
  end
  
  it "constructs poorly injected object given params" do
    foo, bar, qux = 'foo', 'bar', 'qux'
    controller = PoorlyInjectedController.new :foo => foo, :bar => bar, :qux => qux
    controller.foo.should equal(foo)
    controller.bar.should equal(bar)
    controller.qux.should equal(qux)
  end
  
  
  it "raises for an injected object given only partial params" do
    lambda { InjectedController.new(:foo => 'foo') }.should raise_error(Constructor::ArgumentError, /bar/i)
    err = assert_raise Constructor::ArgumentError do
      InjectedController.new :foo => 'foo'
    end
    assert_match(/bar/i, err.message) 
  end
  
  context 'with an invalid context file' do
    before do
      set_context 'not a file path'  
    end
    
    after do
      set_context "#{::Rails.root}/config/objects.yml"
    end
  
    it "allows an injected object that is given params to have a non-existent context file" do
      foo, bar = 'foo', 'bar'
      controller = InjectedController.new :foo => foo, :bar => bar
      controller.should_not be_nil
      controller.foo.should equal(foo)
      controller.bar.should equal(bar)
    end
  
    it "does not affect a normal object when set to a non-existent context file" do
      foo, bar = 'foo', 'bar'
      NormalController.new.should_not be_nil
    end
  end
  
  it "supports object inheritance" do
    GalaxyController.new.foo.should be_a_kind_of(TheFooClass)
    
    controller = SpiralGalaxyController.new
    injected_controller = SpiralGalaxyController.new(:foo => "foo", :bar => "bar")
    SpiralGalaxyController.superclass.should == GalaxyController
  
    controller.foo.should be_a_kind_of(TheFooClass)
    controller.bar.should be_a_kind_of(Bar)
    injected_controller.foo.should == "foo"
    injected_controller.bar.should == "bar"
    
    controller = MilkyWayGalaxyController.new
    injected_controller = MilkyWayGalaxyController.new(:foo => "foo", :bar => "bar", :foo_piece_two => "foo2")
    MilkyWayGalaxyController.superclass.should == SpiralGalaxyController
    controller.foo.should be_a_kind_of(TheFooClass)
    assert_kind_of(TheFooClass, controller.foo)
    controller.bar.should be_a_kind_of(Bar)
    controller.foo_piece_two.should be_a_kind_of(FooPieceTwo)
    injected_controller.foo.should == "foo"
    injected_controller.bar.should == "bar"
    injected_controller.foo_piece_two.should == "foo2"
      
    controller = FutureMilkyWayGalaxyController.new
    injected_controller = FutureMilkyWayGalaxyController.new(:foo => "foo", :bar => "bar", :foo_piece_two => "foo2")
    FutureMilkyWayGalaxyController.superclass.should == MilkyWayGalaxyController
    controller.foo.should be_a_kind_of(TheFooClass)
    assert_kind_of(TheFooClass, controller.foo)
    controller.bar.should be_a_kind_of(Bar)
    controller.foo_piece_two.should be_a_kind_of(FooPieceTwo)
    injected_controller.foo.should == "foo"
    injected_controller.bar.should == "bar"
    injected_controller.foo_piece_two.should == "foo2"
  end

  it "resets the context to having no built components" do
    ic = InjectedController.new 
    ic.foo.should eql(Injection.context['foo'])
    ic.bar.should eql(Injection.context['bar'])
  
    # See that the inject context is being reused, as well as its previously built components:
    ic2 = InjectedController.new 
    ic.foo.should eql(Injection.context['foo'])
    ic.bar.should eql(Injection.context['bar'])
    ic2.foo.should eql(Injection.context['foo'])
    ic2.bar.should eql(Injection.context['bar'])
    ic.foo.foo_piece_one.should eql(Injection.context['foo_piece_one'])
    ic2.foo.foo_piece_one.should eql(Injection.context['foo_piece_one'])
       
    Injection.reset_context
    Injection.context['foo_piece_one'] = "Mock Foo Piece One"
       
    ic3 = InjectedController.new 
    ic3.foo.should eql(Injection.context['foo'])
    ic2.foo.should_not eql(Injection.context['foo'])
    ic.foo.should_not eql(Injection.context['foo'])
    ic3.foo.foo_piece_one.should == "Mock Foo Piece One"
  end
  
  it 'allows extra inputs to be provided when context is reset' do
    lambda { injection_context[:old] }.should raise_error(/failed/i)
    Injection.extra_inputs = {:old => 'spice'}
    Injection.reset_context
    injection_context[:old].should == 'spice'

    CommercialController.new.old.should == 'spice'
  end
   
  it "does not reset context after ActionDispatch::Callbacks" do
    ic = InjectedController.new 
    ic.foo.should eql(Injection.context['foo'])
    ic.bar.should eql(Injection.context['bar'])
  
    # See that the inject context is being reused, as well as its previously built components:
    ic2 = InjectedController.new 
    ic.foo.should eql(Injection.context['foo'])
    ic.bar.should eql(Injection.context['bar'])
    ic2.foo.should eql(Injection.context['foo'])
    ic2.bar.should eql(Injection.context['bar'])
    ic.foo.foo_piece_one.should eql(Injection.context['foo_piece_one'])
    ic2.foo.foo_piece_one.should eql(Injection.context['foo_piece_one'])
  
    # This will trigger the class reloading
    ActionDispatch::Callbacks.new(Proc.new {}, false).call({})
    
    lambda { Injection.context['foo_piece_one'] = "Mock Foo Piece One" }.should raise_error(/already exists/i)
  end
  
end
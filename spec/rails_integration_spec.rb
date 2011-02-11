require 'spec_helper'

describe 'Rails Integration' do
  it "makes the context available to Rails initializers" do
    # There is a config/initializers file that sets the MY_OBJECT to 
    # something from the context
    MY_OBJECT.should be
  end
end
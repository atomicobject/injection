class CoconutController < ActionController::Base
  inject :lime

  def index
    @juice = @lime.squeeze
  end
end

class BananaObserver < ActiveRecord::Observer
  inject :monkey

  before :create do |banana|
    @monkey.peels(banana)
  end
end



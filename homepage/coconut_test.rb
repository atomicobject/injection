class CocunutControllerTest < Test::Unit::TestCase
  include Hardmock

  def setup
    @controller = CoconutController.new(create_mock(:lime))
    @request    = ActionController::TestRequst.new
    @response   = ActionController::TestResponse.new
  end

  def test_index
    @lime.expects(:squeeze).returns('lime juice')
    get :index
    assert_equal 'lime juice', assigns(:juice)
  end
end

class BananaObserverTest < Test::Unit::TestCase
  include Hardmock

  def setup
    @target = BananaObserver.send(:new, create_mock(:monkey))
    @banana = Banana.new
  end

  def test_before_create
    @monkey_expects.peels(@banana)
    @target.update(:before_create, @banana)
  end
end



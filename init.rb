require 'injection'

ActionController::Base.class_eval do
  include Injection
end

ActiveRecord::Observer.class_eval do
  include Injection
  include Injection::ObserverExtension
end

Injection.init_context(RAILS_ROOT + '/config/objects.yml')


require 'rails'

module Injection
  class Railtie < ::Rails::Railtie
    config.before_configuration do
      Injection.context_file = ::Rails.root.to_s + '/config/objects.yml'
    end
    
    config.before_initialize do
      # Let Rails do the auto loading
      DIY::Context.auto_require = false
      
      # Reload the context from the file
      Injection.reset_context
    end
    
    # Reload the context after each request in development
    initializer "injection.clear_context", :before => :set_clear_dependencies_hook do |app|
      unless app.config.cache_classes
        ::ActionDispatch::Callbacks.after do
          Injection.reset_context
        end
      end
    end
    
    initializer "injection.initialize_action_controller" do |app|
      ::ActiveSupport.on_load(:action_controller) do
        include ClassInject
      end
    end

    initializer "injection.initialize_observers" do |app|
      ::ActiveSupport.on_load(:active_record) do
        ::ActiveRecord::Observer.class_eval do
          include ClassInject
          include ObserverExtension
        end
      end
    end
  end
end
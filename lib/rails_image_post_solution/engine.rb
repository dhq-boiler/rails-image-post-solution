# frozen_string_literal: true

require "rails/engine"

module RailsImagePostSolution
  class Engine < ::Rails::Engine
    isolate_namespace RailsImagePostSolution

    # Explicitly set engine root
    config.root = File.expand_path('../..', __dir__)

    # Eager load engine classes to ensure they're available
    config.eager_load_paths += %W[
      #{root}/app/controllers
    ]

    # Load admin module and controllers when app prepares
    config.to_prepare do
      # Ensure Admin module is loaded
      unless defined?(RailsImagePostSolution::Admin)
        require Engine.root.join('app/controllers/rails_image_post_solution/admin.rb')
      end

      # Ensure ApplicationController is loaded
      unless defined?(RailsImagePostSolution::ApplicationController)
        require Engine.root.join('app/controllers/rails_image_post_solution/application_controller.rb')
      end

      # Eager load all admin controllers
      Dir[Engine.root.join('app/controllers/rails_image_post_solution/admin/**/*_controller.rb')].each do |file|
        require file
      end
    end

    # Load routes when engine is initialized
    config.after_initialize do
      routes_path = RailsImagePostSolution::Engine.root.join("config", "routes.rb")
      if File.exist?(routes_path)
        RailsImagePostSolution::Engine.class_eval do
          load routes_path
        end

        # After routes are loaded, make helpers available directly
        Rails.application.config.to_prepare do
          # Include in all controllers
          ActionController::Base.include RailsImagePostSolution::Engine.routes.url_helpers
          ActionController::Base.helper RailsImagePostSolution::Engine.routes.url_helpers

          # Include in all views
          ActionView::Base.include RailsImagePostSolution::Engine.routes.url_helpers
        end
      end
    end

    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_bot
      g.factory_bot dir: "spec/factories"
    end

    # Load locales
    config.i18n.load_path += Dir[Engine.root.join("config", "locales", "**", "*.{rb,yml}")]

    initializer "rails_image_post_solution.assets" do |app|
      app.config.assets.paths << root.join("app/assets")
    end
  end
end

# frozen_string_literal: true

require "rails/engine"

module RailsImagePostSolution
  class Engine < ::Rails::Engine
    isolate_namespace RailsImagePostSolution

    # Explicitly set engine root
    config.root = File.expand_path('../..', __dir__)

    # Load routes when engine is initialized
    config.after_initialize do
      routes_path = RailsImagePostSolution::Engine.root.join("config", "routes.rb")
      if File.exist?(routes_path)
        RailsImagePostSolution::Engine.class_eval do
          load routes_path
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

    # Make engine route helpers available in the main application
    initializer "rails_image_post_solution.helpers" do
      ActiveSupport.on_load(:action_controller_base) do
        include RailsImagePostSolution::Engine.routes.url_helpers
        helper RailsImagePostSolution::Engine.routes.url_helpers
      end

      ActiveSupport.on_load(:action_view) do
        include RailsImagePostSolution::Engine.routes.url_helpers
      end
    end
  end
end

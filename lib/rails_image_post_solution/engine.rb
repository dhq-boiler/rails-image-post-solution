# frozen_string_literal: true

require "rails/engine"

module RailsImagePostSolution
  class Engine < ::Rails::Engine
    isolate_namespace RailsImagePostSolution

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

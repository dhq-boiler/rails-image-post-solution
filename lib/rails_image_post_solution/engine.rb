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

    # Make engine route helpers available in the main application
    initializer "rails_image_post_solution.route_helpers" do
      config.after_initialize do
        Rails.application.routes.url_helpers.class_eval do
          # Delegate common route helpers to the engine
          delegate :admin_image_reports_path, :admin_image_reports_url,
                   :admin_image_report_path, :admin_image_report_url,
                   :confirm_admin_image_report_path, :confirm_admin_image_report_url,
                   :dismiss_admin_image_report_path, :dismiss_admin_image_report_url,
                   :admin_users_path, :admin_users_url,
                   :admin_user_path, :admin_user_url,
                   :suspend_admin_user_path, :suspend_admin_user_url,
                   :unsuspend_admin_user_path, :unsuspend_admin_user_url,
                   :ban_admin_user_path, :ban_admin_user_url,
                   :unban_admin_user_path, :unban_admin_user_url,
                   :admin_frozen_posts_path, :admin_frozen_posts_url,
                   :image_reports_path, :image_reports_url,
                   to: RailsImagePostSolution::Engine.routes.url_helpers
        end

        # Also make helpers available in controllers and views
        ActiveSupport.on_load(:action_controller_base) do
          helper RailsImagePostSolution::Engine.routes.url_helpers
        end
      end
    end
  end
end

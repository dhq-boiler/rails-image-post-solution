# frozen_string_literal: true

module RailsImagePostSolution
  class ApplicationController < ::ApplicationController
    # Engine's base controller inherits from host application's ApplicationController
    # This allows the engine to use the host app's authentication methods

    # Include main app's route helpers
    include Rails.application.routes.url_helpers
    helper Rails.application.routes.url_helpers

    # Add engine view path before rendering
    before_action :add_engine_view_path

    # Override require_login to use main_app routes
    def require_login
      unless logged_in?
        redirect_to login_path, alert: I18n.t("errors.messages.login_required")
      end
    end

    # Add require_admin method for admin controllers
    def require_admin
      unless logged_in?
        redirect_to login_path, alert: I18n.t("errors.messages.login_required")
        return
      end

      unless current_user.admin?
        redirect_to root_path, alert: I18n.t("errors.messages.admin_required")
      end
    end

    private

    def add_engine_view_path
      prepend_view_path Engine.root.join("app", "views")
    end

    # Make main_app available as a helper for engine routes
    helper_method :main_app

    def main_app
      Rails.application.routes.url_helpers
    end
  end
end

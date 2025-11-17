# frozen_string_literal: true

module RailsImagePostSolution
  class ApplicationController < ::ApplicationController
    # Engine's base controller inherits from host application's ApplicationController
    # This allows the engine to use the host app's authentication methods

    # Override require_login to use main_app routes
    def require_login
      unless logged_in?
        redirect_to main_app.login_path, alert: I18n.t("errors.messages.login_required")
      end
    end

    # Add require_admin method for admin controllers
    def require_admin
      unless logged_in?
        redirect_to main_app.login_path, alert: I18n.t("errors.messages.login_required")
        return
      end

      unless current_user.admin?
        redirect_to main_app.root_path, alert: I18n.t("errors.messages.admin_required")
      end
    end
  end
end

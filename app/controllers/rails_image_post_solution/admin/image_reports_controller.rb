# frozen_string_literal: true

module RailsImagePostSolution
  module Admin
    class ImageReportsController < ApplicationController
      before_action :require_login
      before_action :require_admin
      before_action :set_report, only: [:show, :confirm, :dismiss]

      def index
        @status_filter = params[:status] || "all"

        @reports = ImageReport.includes(:user, :active_storage_attachment, :reviewed_by)
                             .recent

        # Filter by status
        case @status_filter
        when "pending"
          @reports = @reports.pending
        when "confirmed"
          @reports = @reports.confirmed
        when "dismissed"
          @reports = @reports.dismissed
        when "reviewed"
          @reports = @reports.reviewed
        end

        @reports = @reports.limit(100)

        # Statistics
        @stats = {
          total: ImageReport.count,
          pending: ImageReport.pending.count,
          confirmed: ImageReport.confirmed.count,
          dismissed: ImageReport.dismissed.count,
          reviewed: ImageReport.reviewed.count
        }
      end

      def show
        @attachment = @report.active_storage_attachment
        @reported_user = @attachment.record.user if @attachment.record.respond_to?(:user)
        @all_reports = ImageReport.where(active_storage_attachment_id: @attachment.id)
                                  .includes(:user)
                                  .recent
      end

      def confirm
        @report.update!(
          status: ImageReport::STATUSES[:confirmed],
          reviewed_by: current_user,
          reviewed_at: Time.current
        )

        redirect_to admin_image_reports_path, notice: I18n.t("rails_image_post_solution.flash.admin.report_confirmed")
      end

      def dismiss
        @report.update!(
          status: ImageReport::STATUSES[:dismissed],
          reviewed_by: current_user,
          reviewed_at: Time.current
        )

        redirect_to admin_image_reports_path, notice: I18n.t("rails_image_post_solution.flash.admin.report_dismissed")
      end

      private

      def set_report
        @report = ImageReport.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        redirect_to admin_image_reports_path, alert: I18n.t("rails_image_post_solution.flash.admin.report_not_found")
      end

      def require_admin
        admin_check = RailsImagePostSolution.configuration&.admin_check_method || :admin?

        unless current_user.respond_to?(admin_check) && current_user.public_send(admin_check)
          redirect_to main_app.root_path, alert: I18n.t("rails_image_post_solution.flash.admin.admin_access_only")
        end
      end

      def require_login
        # Call authentication method implemented in host application
        return if respond_to?(:current_user) && current_user

        redirect_to main_app.root_path, alert: I18n.t("rails_image_post_solution.flash.admin.login_required")
      end
    end
  end
end

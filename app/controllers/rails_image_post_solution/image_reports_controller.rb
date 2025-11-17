# frozen_string_literal: true

module RailsImagePostSolution
  class ImageReportsController < ApplicationController
    before_action :require_login
    before_action :set_attachment, only: :create

    def create
      # Check if already reported
      existing_report = ImageReport.find_by(
        active_storage_attachment_id: @attachment.id,
        user_id: current_user.id
      )

      if existing_report
        respond_to do |format|
          format.json do
            render json: { error: I18n.t("rails_image_post_solution.flash.already_reported") },
                   status: :unprocessable_entity
          end
          format.html do
            redirect_back fallback_location: root_path,
                          alert: I18n.t("rails_image_post_solution.flash.already_reported")
          end
        end
        return
      end

      @report = ImageReport.new(
        active_storage_attachment_id: @attachment.id,
        user_id: current_user.id,
        reason: params[:reason],
        status: ImageReport::STATUSES[:pending]
      )

      if @report.save
        # Run image moderation only on first report
        if ImageReport.where(active_storage_attachment_id: @attachment.id).count == 1
          ImageModerationJob.perform_later(@attachment.id)
        end

        respond_to do |format|
          format.json do
            render json: { success: true, message: I18n.t("rails_image_post_solution.flash.report_received") },
                   status: :created
          end
          format.html do
            redirect_back fallback_location: root_path,
                          notice: I18n.t("rails_image_post_solution.flash.report_received")
          end
        end
      else
        respond_to do |format|
          format.json { render json: { error: @report.errors.full_messages.join(", ") }, status: :unprocessable_entity }
          format.html { redirect_back fallback_location: root_path, alert: @report.errors.full_messages.join(", ") }
        end
      end
    end

    private

    def set_attachment
      @attachment = ActiveStorage::Attachment.find(params[:attachment_id])
    rescue ActiveRecord::RecordNotFound
      respond_to do |format|
        format.json do
          render json: { error: I18n.t("rails_image_post_solution.flash.image_not_found") }, status: :not_found
        end
        format.html do
          redirect_back fallback_location: root_path, alert: I18n.t("rails_image_post_solution.flash.image_not_found")
        end
      end
    end

    def require_login
      # Call authentication method implemented in host application
      return if respond_to?(:current_user) && current_user

      respond_to do |format|
        format.json do
          render json: { error: I18n.t("rails_image_post_solution.flash.login_required") }, status: :unauthorized
        end
        format.html { redirect_to main_app.root_path, alert: I18n.t("rails_image_post_solution.flash.login_required") }
      end
    end
  end
end

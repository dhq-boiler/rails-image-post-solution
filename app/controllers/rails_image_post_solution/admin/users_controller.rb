# frozen_string_literal: true

module RailsImagePostSolution
  module Admin
    class UsersController < RailsImagePostSolution::ApplicationController
    before_action :require_login
    before_action :require_admin
    before_action :set_user, only: %i[show suspend unsuspend ban unban]

    def index
      @status_filter = params[:status] || "all"

      @users = User.order(created_at: :desc)

      # Filter by status
      case @status_filter
      when "active"
        @users = @users.select(&:active?)
      when "suspended"
        @users = @users.select(&:suspended?)
      when "banned"
        @users = @users.select(&:banned?)
      when "admin"
        @users = @users.where(admin: true)
      end

      @users = @users.first(100)

      # Statistics
      @stats = {
        total: User.count,
        active: User.all.count(&:active?),
        suspended: User.all.count(&:suspended?),
        banned: User.all.count(&:banned?),
        admin: User.where(admin: true).count
      }
    end

    def show
      @stages = @user.stages.recent.limit(10)
      @comments = @user.multiplay_recruitment_comments.order(created_at: :desc).limit(10)
      @reports_made = ImageReport.where(user_id: @user.id).order(created_at: :desc).limit(10)

      # Reports against this user's images
      @reports_received = ImageReport
                          .joins(active_storage_attachment: :blob)
                          .where(active_storage_attachments: { record_type: %w[Stage MultiplayRecruitmentComment] })
                          .where("active_storage_attachments.record_id IN (
          SELECT id FROM stages WHERE user_id = :user_id
          UNION
          SELECT id FROM multiplay_recruitment_comments WHERE user_id = :user_id
        )", user_id: @user.id)
                          .order(created_at: :desc)
                          .limit(10)
    end

    def suspend
      duration_days = params[:duration]&.to_i || 7
      reason = params[:reason]

      @user.suspend!(reason: reason, duration: duration_days.days)

      redirect_to admin_user_path(@user),
                  notice: I18n.t("admin.flash.user_suspended", name: @user.display_name, days: duration_days)
    end

    def unsuspend
      @user.unsuspend!

      redirect_to admin_user_path(@user), notice: I18n.t("admin.flash.user_unsuspended", name: @user.display_name)
    end

    def ban
      reason = params[:reason]

      @user.ban!(reason: reason)

      redirect_to admin_user_path(@user), notice: I18n.t("admin.flash.user_banned", name: @user.display_name)
    end

    def unban
      @user.unban!

      redirect_to admin_user_path(@user), notice: I18n.t("admin.flash.user_unbanned", name: @user.display_name)
    end

    private

    def set_user
      @user = User.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_users_path, alert: I18n.t("admin.flash.user_not_found")
    end

    def require_admin
      return if current_user.admin?

      redirect_to root_path, alert: I18n.t("admin.flash.admin_access_only")
    end
    end
  end
end

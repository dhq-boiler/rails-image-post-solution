# frozen_string_literal: true

module RailsImagePostSolution
  module Admin
    class FrozenPostsController < ApplicationController
    before_action :require_login
    before_action :require_admin

    def index
      @filter = params[:filter] || "all"

      # Get frozen stages and comments
      stages = Stage.frozen.includes(:user).recent
      comments = MultiplayRecruitmentComment.frozen.includes(:user, :multiplay_recruitment).recent

      case @filter
      when "temporary"
        stages = stages.temporarily_frozen
        comments = comments.temporarily_frozen
      when "permanent"
        stages = stages.permanently_frozen
        comments = comments.permanently_frozen
      end

      # Combine into array and sort by frozen_at
      @frozen_posts = (stages.to_a + comments.to_a).sort_by(&:frozen_at).reverse

      # Statistics
      @stats = {
        total: Stage.frozen.count + MultiplayRecruitmentComment.frozen.count,
        temporary: Stage.temporarily_frozen.count + MultiplayRecruitmentComment.temporarily_frozen.count,
        permanent: Stage.permanently_frozen.count + MultiplayRecruitmentComment.permanently_frozen.count
      }
    end

    def unfreeze_stage
      stage = Stage.find(params[:id])
      stage.unfreeze!
      redirect_to admin_frozen_posts_path, notice: I18n.t("admin.flash.stage_unfrozen")
    end

    def unfreeze_comment
      comment = MultiplayRecruitmentComment.find(params[:id])
      comment.unfreeze!
      redirect_to admin_frozen_posts_path, notice: I18n.t("admin.flash.comment_unfrozen")
    end

    def permanent_freeze_stage
      stage = Stage.find(params[:id])
      stage.freeze_post!(type: :permanent, reason: params[:reason] || I18n.t("admin.flash.permanent_freeze_by_admin"))
      redirect_to admin_frozen_posts_path, notice: I18n.t("admin.flash.stage_permanently_frozen")
    end

    def permanent_freeze_comment
      comment = MultiplayRecruitmentComment.find(params[:id])
      comment.freeze_post!(type: :permanent, reason: params[:reason] || I18n.t("admin.flash.permanent_freeze_by_admin"))
      redirect_to admin_frozen_posts_path, notice: I18n.t("admin.flash.comment_permanently_frozen")
    end

    def destroy_stage
      stage = Stage.find(params[:id])
      stage.destroy
      redirect_to admin_frozen_posts_path, notice: I18n.t("admin.flash.stage_deleted")
    end

    def destroy_comment
      comment = MultiplayRecruitmentComment.find(params[:id])
      comment.destroy
      redirect_to admin_frozen_posts_path, notice: I18n.t("admin.flash.comment_deleted")
    end

    private

    def require_admin
      return if current_user.admin?

      redirect_to root_path, alert: I18n.t("admin.flash.access_denied")
    end
    end
  end
end

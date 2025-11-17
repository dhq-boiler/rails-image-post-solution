# frozen_string_literal: true

module RailsImagePostSolution
  class ImageModerationJob < ApplicationJob
    queue_as :default

    # Job to perform automatic image moderation
    # Uses OpenAI Vision API to detect R18/R18G content
    def perform(attachment_id)
      attachment = ActiveStorage::Attachment.find_by(id: attachment_id)
      return unless attachment&.blob

      # Analyze image using OpenAI Vision Service
      result = OpenaiVisionService.new.moderate_image(attachment)

      # Process results
      if result[:flagged]
        # Create automatic report when inappropriate content is detected
        create_auto_report(attachment, result)

        # Temporarily freeze post (if enabled in config)
        freeze_post(attachment, result) if auto_freeze_enabled?
      end

      Rails.logger.info "Image moderation completed for attachment ##{attachment_id}: #{result[:flagged] ? 'FLAGGED' : 'OK'}"
    rescue StandardError => e
      Rails.logger.error "Image moderation failed for attachment ##{attachment_id}: #{e.message}"
      # Don't fail the job on error (leave for manual review)
    end

    private

    def auto_freeze_enabled?
      RailsImagePostSolution.configuration&.auto_freeze_on_flag != false
    end

    def create_auto_report(attachment, result)
      # Create automatic report as system user (nil user_id)
      # Skip if automatic report already exists
      existing_report = ImageReport.find_by(
        active_storage_attachment_id: attachment.id,
        user_id: nil # Automatic report by system
      )

      return if existing_report

      ImageReport.create!(
        active_storage_attachment: attachment,
        user_id: nil, # Automatic report by system
        reason: build_auto_report_reason(result),
        status: ImageReport::STATUSES[:confirmed], # Automatically set to confirmed (inappropriate)
        reviewed_at: Time.current,
        ai_flagged: result[:flagged],
        ai_confidence: result[:confidence],
        ai_categories: result[:categories].to_json,
        ai_detected_at: Time.current
      )
    end

    def build_auto_report_reason(result)
      reasons = []
      reasons << "Auto-detected: Inappropriate content detected"

      if result[:categories]
        flagged_categories = result[:categories].select { |_, flagged| flagged }
        if flagged_categories.any?
          reasons << "\nDetected categories:"
          flagged_categories.each do |category, _|
            reasons << "  - #{category}"
          end
        end
      end

      if result[:confidence]
        reasons << "\nConfidence: #{(result[:confidence] * 100).round(1)}%"
      end

      reasons.join("\n")
    end

    # Temporarily freeze post
    # Only works if host application implements freeze_post! method
    def freeze_post(attachment, result)
      record = attachment.record
      return unless record
      return unless record.respond_to?(:freeze_post!)

      # Skip if already frozen
      return if record.respond_to?(:frozen?) && record.frozen?

      reason = "AI Auto-moderation: Post has been temporarily frozen due to inappropriate content detection.\n#{build_auto_report_reason(result)}"

      record.freeze_post!(type: :temporary, reason: reason)
      Rails.logger.info "Post #{record.class.name}##{record.id} has been temporarily frozen due to inappropriate content"
    rescue StandardError => e
      Rails.logger.error "Failed to freeze post for attachment ##{attachment.id}: #{e.message}"
    end
  end
end

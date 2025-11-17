# frozen_string_literal: true

module RailsImagePostSolution
  class ImageReport < ApplicationRecord
    self.table_name = "image_reports"

    # Status constants
    STATUSES = {
      pending: "pending",         # Not reviewed yet
      reviewed: "reviewed",       # Reviewed (no action needed)
      confirmed: "confirmed",     # Confirmed (flagged as inappropriate)
      dismissed: "dismissed"      # Dismissed (no issues found)
    }.freeze

    # Report reason category keys (translations via I18n.t("rails_image_post_solution.image_report.categories.#{key}"))
    REASON_CATEGORIES = %i[r18 r18g copyright spam harassment other].freeze

    # Get category translation text
    def self.category_text(key)
      I18n.t("rails_image_post_solution.image_report.categories.#{key}")
    end

    # Get category list (for use in views)
    def self.categories_for_select
      REASON_CATEGORIES.map { |key| [ key, category_text(key) ] }
    end

    # Associations
    belongs_to :active_storage_attachment, class_name: "ActiveStorage::Attachment"
    belongs_to :user
    belongs_to :reviewed_by, class_name: "User", optional: true

    # Validations
    validates :status, presence: true, inclusion: { in: STATUSES.values }
    validates :user_id, uniqueness: { scope: :active_storage_attachment_id,
                                      message: "has already reported this image" }

    # Scopes
    scope :pending, -> { where(status: STATUSES[:pending]) }
    scope :reviewed, -> { where(status: STATUSES[:reviewed]) }
    scope :confirmed, -> { where(status: STATUSES[:confirmed]) }
    scope :dismissed, -> { where(status: STATUSES[:dismissed]) }
    scope :recent, -> { order(created_at: :desc) }

    # Check if image has been reported as inappropriate
    def self.image_reported?(attachment_id)
      where(active_storage_attachment_id: attachment_id)
        .where(status: [ STATUSES[:pending], STATUSES[:confirmed] ])
        .exists?
    end

    # Get report count for image
    def self.report_count(attachment_id)
      where(active_storage_attachment_id: attachment_id).count
    end
  end
end

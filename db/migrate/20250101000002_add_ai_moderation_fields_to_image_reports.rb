# frozen_string_literal: true

class AddAiModerationFieldsToImageReports < ActiveRecord::Migration[7.0]
  def change
    add_column :image_reports, :ai_flagged, :boolean, default: false
    add_column :image_reports, :ai_confidence, :float
    add_column :image_reports, :ai_categories, :text
    add_column :image_reports, :ai_detected_at, :datetime

    add_index :image_reports, :ai_flagged
  end
end

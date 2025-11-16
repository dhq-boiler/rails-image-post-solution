# frozen_string_literal: true

class CreateRailsImagePostSolutionImageReports < ActiveRecord::Migration[7.0]
  def change
    create_table :image_reports do |t|
      t.references :active_storage_attachment, null: false, foreign_key: true
      t.references :user, null: true, foreign_key: true
      t.text :reason
      t.string :status, null: false, default: "pending"
      t.references :reviewed_by, foreign_key: { to_table: :users }
      t.datetime :reviewed_at

      t.timestamps
    end

    add_index :image_reports, [:active_storage_attachment_id, :user_id], unique: true, name: "index_image_reports_on_attachment_and_user"
    add_index :image_reports, :status
  end
end

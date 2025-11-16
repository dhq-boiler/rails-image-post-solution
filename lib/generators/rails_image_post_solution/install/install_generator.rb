# frozen_string_literal: true

require "rails/generators/base"
require "rails/generators/migration"

module RailsImagePostSolution
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path("templates", __dir__)

      desc "Creates an initializer and copies migrations for RailsImagePostSolution"

      def self.next_migration_number(dirname)
        next_migration_number = current_migration_number(dirname) + 1
        ActiveRecord::Migration.next_migration_number(next_migration_number)
      end

      def copy_initializer
        template "rails_image_post_solution.rb", "config/initializers/rails_image_post_solution.rb"
      end

      def copy_migrations
        migration_template "create_image_reports.rb.erb",
                           "db/migrate/create_rails_image_post_solution_image_reports.rb",
                           migration_version: migration_version

        sleep 1 # Ensure different timestamps

        migration_template "add_ai_moderation_fields.rb.erb",
                           "db/migrate/add_ai_moderation_fields_to_image_reports.rb",
                           migration_version: migration_version
      end

      def show_readme
        readme "README" if behavior == :invoke
      end

      private

      def migration_version
        "[#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}]"
      end
    end
  end
end

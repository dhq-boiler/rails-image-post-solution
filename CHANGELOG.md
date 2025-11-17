# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2025-01-17

### Added
- Initial release of RailsImagePostSolution
- Image reporting system for Active Storage attachments
- AI-powered moderation using OpenAI Vision API
  - Detects R18 (adult content)
  - Detects R18G (grotesque/violent content)
  - Detects illegal content
- Admin dashboard for reviewing image reports
  - View all reports with filtering by status
  - Detailed report view with image preview
  - Confirm or dismiss reports
  - View AI moderation results
- Auto-freeze functionality for inappropriate content
- Rails generator for easy installation (`rails generate rails_image_post_solution:install`)
- Configuration system with initializer
- i18n support (Japanese and English)
- Database migrations for image_reports table
- User reporting API endpoint
- Comprehensive README with installation and usage instructions

### Features
- Configurable OpenAI API key
- Configurable admin check method
- Optional auto-freeze on content flagged by AI
- Support for nil user_id (system/AI reports)
- Unique index to prevent duplicate reports from same user
- AI confidence scores and category detection
- View helper methods for easy integration

[Unreleased]: https://github.com/dhq-boiler/rails-image-post-solution/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/dhq-boiler/rails-image-post-solution/releases/tag/v0.1.0

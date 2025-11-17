# RailsImagePostSolution

A comprehensive Rails engine for image reporting, AI-powered moderation using OpenAI Vision API, and admin dashboard. Perfect for Rails applications using Active Storage that need to moderate user-generated image content.

## Features

- 📸 **Image Reporting System**: Allow users to report inappropriate images
- 🤖 **AI-Powered Moderation**: Automatic content moderation using OpenAI Vision API
  - Detects R18 (adult content)
  - Detects R18G (grotesque/violent content)
  - Detects illegal content
- 👮 **Admin Dashboard**: Review and manage reported images
- 🔒 **Auto-Freeze**: Automatically freeze posts containing flagged content (configurable)
- 🌍 **i18n Support**: Japanese and English locales included
- ⚙️ **Highly Configurable**: Customize behavior to fit your application

## Requirements

- Ruby >= 3.2.0
- Rails >= 7.0
- Active Storage
- OpenAI API key (for AI moderation features)

## Installation

Add this line to your application's Gemfile:

```ruby
gem "rails-image-post-solution"
```

And then execute:

```bash
bundle install
```

Run the installation generator:

```bash
rails generate rails_image_post_solution:install
```

This will:
1. Create an initializer at `config/initializers/rails_image_post_solution.rb`
2. Copy migration files to your application
3. Display installation instructions

Run the migrations:

```bash
rails db:migrate
```

Mount the engine in your `config/routes.rb`:

```ruby
Rails.application.routes.draw do
  mount RailsImagePostSolution::Engine => "/moderation"
  # ... your other routes
end
```

## Configuration

Edit `config/initializers/rails_image_post_solution.rb`:

```ruby
RailsImagePostSolution.configure do |config|
  # OpenAI API key (recommended to use environment variable)
  config.openai_api_key = ENV["OPENAI_API_KEY"]

  # Auto-freeze posts when inappropriate content is detected
  # Default: true
  config.auto_freeze_on_flag = true

  # Method name to check if current_user is admin
  # Default: :admin?
  config.admin_check_method = :admin?
end
```

Set your OpenAI API key as an environment variable:

```bash
export OPENAI_API_KEY=sk-...
```

## Usage

### User Reporting

Users can report images via POST request:

```ruby
# In your view
<%= button_to "Report", rails_image_post_solution.image_reports_path(attachment_id: @image.id, reason: "Inappropriate content"), method: :post %>
```

Or via JavaScript:

```javascript
fetch('/moderation/image_reports', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
  },
  body: JSON.stringify({
    attachment_id: imageId,
    reason: 'R18 content'
  })
});
```

### Admin Dashboard

Admins can access the dashboard at:

```
/moderation/admin/image_reports
```

Features:
- View all reports
- Filter by status (pending, confirmed, dismissed, reviewed)
- View detailed information about each report
- Mark reports as confirmed (inappropriate) or dismissed (safe)
- View AI moderation results

### AI Moderation

AI moderation runs automatically when the first report is submitted for an image. You can also trigger it manually:

```ruby
RailsImagePostSolution::ImageModerationJob.perform_later(attachment_id)
```

### Post Freezing (Optional)

To enable automatic post freezing, add a `freeze_post!` method to your models that have images:

```ruby
class Post < ApplicationRecord
  has_many_attached :images

  def freeze_post!(type:, reason:)
    update!(
      frozen: true,
      frozen_type: type,
      frozen_reason: reason,
      frozen_at: Time.current
    )
  end

  def frozen?
    frozen == true
  end
end
```

## Requirements for Host Application

Your Rails application must have:

1. **Active Storage** configured
2. **User model** with:
   - `current_user` helper method in controllers
   - `admin?` method (or custom method specified in config)
   - Display name method (tries `display_name` or `name`)

Example User model:

```ruby
class User < ApplicationRecord
  def admin?
    role == "admin"
  end

  def display_name
    name || email
  end
end
```

## Routes

The engine provides the following routes:

```
POST   /moderation/image_reports                        # Create report
GET    /moderation/admin/image_reports                  # List all reports
GET    /moderation/admin/image_reports/:id              # View report details
PATCH  /moderation/admin/image_reports/:id/confirm      # Mark as inappropriate
PATCH  /moderation/admin/image_reports/:id/dismiss      # Mark as safe
```

## Customization

### Custom Admin Check

You can customize how admin access is checked:

```ruby
# config/initializers/rails_image_post_solution.rb
config.admin_check_method = :moderator?  # or any method name
```

### Custom Styling

Override the engine's views by creating files in your app:

```
app/views/rails_image_post_solution/admin/image_reports/index.html.erb
app/views/rails_image_post_solution/admin/image_reports/show.html.erb
```

### Custom Moderation Logic

You can subclass and override the moderation job:

```ruby
class CustomImageModerationJob < RailsImagePostSolution::ImageModerationJob
  def perform(attachment_id)
    # Your custom logic
    super
  end
end
```

## Database Schema

The gem creates one table: `image_reports`

| Column                         | Type     | Description                          |
|--------------------------------|----------|--------------------------------------|
| active_storage_attachment_id   | integer  | Reference to Active Storage          |
| user_id                        | integer  | Reporter (null for AI reports)       |
| reason                         | text     | Reason for report                    |
| status                         | string   | pending/confirmed/dismissed/reviewed |
| reviewed_by_id                 | integer  | Admin who reviewed                   |
| reviewed_at                    | datetime | When reviewed                        |
| ai_flagged                     | boolean  | Flagged by AI                        |
| ai_confidence                  | float    | AI confidence score (0.0-1.0)        |
| ai_categories                  | text     | JSON of detected categories          |
| ai_detected_at                 | datetime | When AI detection ran                |

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/dhq-boiler/rails-image-post-solution.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Author

dhq_boiler (dhq_boiler@live.jp)

# RailsImagePostSolution

A comprehensive Rails engine for image reporting, AI-powered moderation using OpenAI Vision API, and admin dashboard. Perfect for Rails applications using Active Storage that need to moderate user-generated image content.

## Features

### Core Features
- **Image Reporting System**: Allow users to report inappropriate images
- **AI-Powered Moderation**: Automatic content moderation using OpenAI Vision API
  - Detects R18 (adult content)
  - Detects R18G (grotesque/violent content)
  - Detects illegal content
- **Admin Dashboard**: Review and manage reported images
- **Auto-Freeze**: Automatically freeze posts containing flagged content (configurable)
- **i18n Support**: Japanese and English locales included
- **Highly Configurable**: Customize behavior to fit your application

### Extended Admin Features (Optional)
- **User Management**: Suspend, ban, and manage users
- **Frozen Posts Management**: Review, unfreeze, or permanently freeze flagged content
- **Enhanced Reporting**: Extended admin views with detailed statistics

## Requirements

- Ruby >= 3.4.7
- Rails >= 8.1
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
  # Mount the engine
  mount RailsImagePostSolution::Engine => "/moderation"

  # Optional: Add admin routes for extended features (user management, frozen posts)
  namespace :admin do
    resources :users, only: %i[index show] do
      member do
        post :suspend
        post :unsuspend
        post :ban
        post :unban
      end
    end

    resources :frozen_posts, only: [:index] do
      collection do
        post "unfreeze_stage/:id", to: "frozen_posts#unfreeze_stage", as: :unfreeze_stage
        post "unfreeze_comment/:id", to: "frozen_posts#unfreeze_comment", as: :unfreeze_comment
        post "permanent_freeze_stage/:id", to: "frozen_posts#permanent_freeze_stage", as: :permanent_freeze_stage
        post "permanent_freeze_comment/:id", to: "frozen_posts#permanent_freeze_comment", as: :permanent_freeze_comment
        delete "destroy_stage/:id", to: "frozen_posts#destroy_stage", as: :destroy_stage
        delete "destroy_comment/:id", to: "frozen_posts#destroy_comment", as: :destroy_comment
      end
    end
  end

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

The gem provides shared view partials for easy integration:

```erb
<%# In your view %>
<%= render 'shared/image_report_button', image: @attachment %>
<%= render 'shared/image_report_modal' %>
```

Or manually via POST request:

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

The provided partials include:
- `_image_report_button.html.erb` - Report button with status display
- `_image_report_modal.html.erb` - Modal dialog for submitting reports with category selection

**Note**: The partials reference Stimulus controllers (`image-report`). You'll need to implement the corresponding Stimulus controller in your application or use the manual POST method above.

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

  # Scopes for frozen posts management
  scope :frozen, -> { where.not(frozen_at: nil) }
  scope :temporarily_frozen, -> { frozen.where(frozen_type: "temporary") }
  scope :permanently_frozen, -> { frozen.where(frozen_type: "permanent") }
  scope :recent, -> { order(created_at: :desc) }

  def freeze_post!(type:, reason:)
    update!(
      frozen_type: type,
      frozen_reason: reason,
      frozen_at: Time.current
    )
  end

  def unfreeze!
    update!(
      frozen_type: nil,
      frozen_reason: nil,
      frozen_at: nil
    )
  end

  def frozen?
    frozen_at.present?
  end
end
```

Add the required columns to your model:

```ruby
class AddFrozenFieldsToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :frozen_type, :string
    add_column :posts, :frozen_reason, :text
    add_column :posts, :frozen_at, :datetime
    add_index :posts, :frozen_at
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

### Additional User Model Methods (for Extended Features)

If you plan to use the extended admin features (user management, frozen posts), add these methods to your User model:

```ruby
class User < ApplicationRecord
  # Status check methods
  def active?
    !suspended? && !banned?
  end

  def suspended?
    suspended_until.present? && suspended_until > Time.current
  end

  def banned?
    banned_at.present?
  end

  # User management methods
  def suspend!(reason:, duration: 7.days)
    update!(
      suspended_until: Time.current + duration,
      suspension_reason: reason
    )
  end

  def unsuspend!
    update!(
      suspended_until: nil,
      suspension_reason: nil
    )
  end

  def ban!(reason:)
    update!(
      banned_at: Time.current,
      ban_reason: reason
    )
  end

  def unban!
    update!(
      banned_at: nil,
      ban_reason: nil
    )
  end
end
```

And add the corresponding database columns:

```ruby
class AddModerationFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :suspended_until, :datetime
    add_column :users, :suspension_reason, :text
    add_column :users, :banned_at, :datetime
    add_column :users, :ban_reason, :text
  end
end
```

## Routes

### Engine Routes (via /moderation mount point)

The engine provides these routes when mounted at `/moderation`:

```
POST   /moderation/image_reports                        # Create report
GET    /moderation/admin/image_reports                  # List all reports
GET    /moderation/admin/image_reports/:id              # View report details
PATCH  /moderation/admin/image_reports/:id/confirm      # Mark as inappropriate
PATCH  /moderation/admin/image_reports/:id/dismiss      # Mark as safe
```

### Host Application Routes (Required for Extended Features)

The gem provides additional admin controllers in `app/controllers/admin/` that you can use in your host application. **You must add these routes to your host application's `config/routes.rb`** to use them:

```ruby
namespace :admin do
  # User management
  resources :users, only: %i[index show] do
    member do
      post :suspend
      post :unsuspend
      post :ban
      post :unban
    end
  end

  # Frozen posts management
  resources :frozen_posts, only: [:index] do
    collection do
      post "unfreeze_stage/:id", to: "frozen_posts#unfreeze_stage", as: :admin_unfreeze_stage
      post "unfreeze_comment/:id", to: "frozen_posts#unfreeze_comment", as: :admin_unfreeze_comment
      post "permanent_freeze_stage/:id", to: "frozen_posts#permanent_freeze_stage", as: :admin_permanent_freeze_stage
      post "permanent_freeze_comment/:id", to: "frozen_posts#permanent_freeze_comment", as: :admin_permanent_freeze_comment
      delete "destroy_stage/:id", to: "frozen_posts#destroy_stage", as: :admin_destroy_stage
      delete "destroy_comment/:id", to: "frozen_posts#destroy_comment", as: :admin_destroy_comment
    end
  end
end
```

This provides these routes:

```
GET    /admin/users                                     # List all users
GET    /admin/users/:id                                 # View user details
POST   /admin/users/:id/suspend                         # Suspend user
POST   /admin/users/:id/unsuspend                       # Unsuspend user
POST   /admin/users/:id/ban                             # Ban user
POST   /admin/users/:id/unban                           # Unban user
GET    /admin/frozen_posts                              # List frozen posts
POST   /admin/frozen_posts/unfreeze_stage/:id           # Unfreeze a stage
POST   /admin/frozen_posts/unfreeze_comment/:id         # Unfreeze a comment
POST   /admin/frozen_posts/permanent_freeze_stage/:id   # Permanently freeze a stage
POST   /admin/frozen_posts/permanent_freeze_comment/:id # Permanently freeze a comment
DELETE /admin/frozen_posts/destroy_stage/:id            # Delete a frozen stage
DELETE /admin/frozen_posts/destroy_comment/:id          # Delete a frozen comment
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

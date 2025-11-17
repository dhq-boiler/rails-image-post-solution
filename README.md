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

### Internationalization
- **Full i18n Support**: Seamlessly integrates with locale-scoped routes
- **15+ Languages**: Supports ja, en, ko, zh-CN, zh-TW, es, fr, de, ru, th, vi, id, pt, tr, it
- **Automatic Locale Handling**: Works with your application's locale configuration

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

**For applications WITH locale-scoped routes:**

```ruby
Rails.application.routes.draw do
  # Wrap all routes including the engine mount in a locale scope
  scope "(:locale)", locale: /[a-z]{2}(-[A-Z]{2})?/ do
    # Mount the engine - all admin features will be accessible at /:locale/moderation/admin/*
    mount RailsImagePostSolution::Engine => "/moderation"

    # ... your other routes
  end
end
```

**For applications WITHOUT locale-scoped routes:**

```ruby
Rails.application.routes.draw do
  # Mount the engine - all admin features will be accessible at /moderation/admin/*
  mount RailsImagePostSolution::Engine => "/moderation"

  # ... your other routes
end
```

**Important**: The engine itself does NOT add locale scoping to its internal routes. Locale handling should be done at the mount level in the host application's routes file.

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
# Without locale
/moderation/admin/image_reports

# With locale (if using locale-scoped routes)
/ja/moderation/admin/image_reports
/en/moderation/admin/image_reports
/de/moderation/admin/image_reports
# ... etc
```

Features:
- View all reports
- Filter by status (pending, confirmed, dismissed, reviewed)
- View detailed information about each report
- Mark reports as confirmed (inappropriate) or dismissed (safe)
- View AI moderation results
- Multi-language support (automatically uses your application's current locale)

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

The engine provides the following routes when mounted at `/moderation`:

### Using Route Helpers

The engine automatically makes route helpers available in your application:

**In host application views/controllers** (accessing host app routes):
```ruby
# Use main_app prefix to access host application routes
main_app.root_path(locale: I18n.locale)           # => /ja/
main_app.stages_path(locale: I18n.locale)         # => /ja/stages
main_app.user_path(@user, locale: I18n.locale)   # => /ja/users/:id
```

**Accessing engine routes from host application:**
```ruby
# Use engine namespace
rails_image_post_solution.admin_image_reports_path    # => /moderation/admin/image_reports (or /ja/moderation/admin/image_reports)
rails_image_post_solution.admin_user_path(@user)      # => /moderation/admin/users/:id
rails_image_post_solution.image_reports_path          # => /moderation/image_reports

# In locale-scoped applications, locale is automatically included via mount point
```

**In engine views/controllers:**
```ruby
# Engine routes (no prefix needed within engine)
admin_image_reports_path                    # => /admin/image_reports
admin_user_path(id: @user.id)              # => /admin/users/:id

# Host app routes (use main_app prefix)
main_app.root_path(locale: I18n.locale)    # => /ja/
```

### User-Facing Routes

```
POST   (/:locale)/moderation/image_reports                        # Create report
```

### Admin Routes

**Image Reports:**
```
GET    (/:locale)/moderation/admin/image_reports                  # List all reports
GET    (/:locale)/moderation/admin/image_reports/:id              # View report details
PATCH  (/:locale)/moderation/admin/image_reports/:id/confirm      # Mark as inappropriate
PATCH  (/:locale)/moderation/admin/image_reports/:id/dismiss      # Mark as safe
```

**User Management:**
```
GET    (/:locale)/moderation/admin/users                          # List all users
GET    (/:locale)/moderation/admin/users/:id                      # View user details
POST   (/:locale)/moderation/admin/users/:id/suspend              # Suspend user
POST   (/:locale)/moderation/admin/users/:id/unsuspend            # Unsuspend user
POST   (/:locale)/moderation/admin/users/:id/ban                  # Ban user
POST   (/:locale)/moderation/admin/users/:id/unban                # Unban user
```

**Frozen Posts:**
```
GET    (/:locale)/moderation/admin/frozen_posts                                  # List frozen posts
POST   (/:locale)/moderation/admin/frozen_posts/unfreeze_stage/:id              # Unfreeze a stage
POST   (/:locale)/moderation/admin/frozen_posts/unfreeze_comment/:id            # Unfreeze a comment
POST   (/:locale)/moderation/admin/frozen_posts/permanent_freeze_stage/:id      # Permanently freeze a stage
POST   (/:locale)/moderation/admin/frozen_posts/permanent_freeze_comment/:id    # Permanently freeze a comment
DELETE (/:locale)/moderation/admin/frozen_posts/destroy_stage/:id               # Delete a frozen stage
DELETE (/:locale)/moderation/admin/frozen_posts/destroy_comment/:id             # Delete a frozen comment
```

Note: `(/:locale)` means the locale parameter is optional and depends on your application's routing configuration.

## Internationalization (i18n)

### Supported Languages

The engine includes translations for 15 languages:
- 🇯🇵 Japanese (ja)
- 🇺🇸 English (en)
- 🇰🇷 Korean (ko)
- 🇨🇳 Simplified Chinese (zh-CN)
- 🇹🇼 Traditional Chinese (zh-TW)
- 🇪🇸 Spanish (es)
- 🇫🇷 French (fr)
- 🇩🇪 German (de)
- 🇷🇺 Russian (ru)
- 🇹🇭 Thai (th)
- 🇻🇳 Vietnamese (vi)
- 🇮🇩 Indonesian (id)
- 🇵🇹 Portuguese (pt)
- 🇹🇷 Turkish (tr)
- 🇮🇹 Italian (it)

### Locale Configuration

The engine automatically uses your application's `I18n.locale`. To configure available locales in your host application:

```ruby
# config/application.rb
config.i18n.available_locales = [:ja, :en, :ko, :zh_CN, :zh_TW, :es, :fr, :de, :ru, :th, :vi, :id, :pt, :tr, :it]
config.i18n.default_locale = :ja
```

### Language Switching in Views

When implementing language switching in your application header, use this pattern to preserve the current path with different locales:

```erb
<% I18n.available_locales.each do |locale| %>
  <%
    # Preserve query parameters but replace locale in the path
    new_path = request.path.sub(%r{^/([a-z]{2}(-[A-Z]{2})?)(/|$)}, "/#{locale}\\3")

    # If path doesn't start with a locale, add one
    unless request.path.match?(%r{^/[a-z]{2}(-[A-Z]{2})?(/|$)})
      new_path = "/#{locale}#{request.path}"
    end

    new_path += "?#{request.query_string}" if request.query_string.present?
  %>
  <%= link_to t("languages.#{locale}"), new_path, class: "language-menu-item #{'active' if I18n.locale == locale}" %>
<% end %>
```

This ensures that users can switch languages while staying on the same page, whether they're in the host application or the engine's admin pages.

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

### Custom Locale Management

The engine respects your application's locale configuration. If you need custom locale handling:

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :set_locale

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end

  def default_url_options
    { locale: I18n.locale }
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

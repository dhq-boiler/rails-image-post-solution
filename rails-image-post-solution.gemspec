# frozen_string_literal: true

require_relative 'lib/rails_image_post_solution/version'

Gem::Specification.new do |spec|
  spec.name = 'rails-image-post-solution'
  spec.version = RailsImagePostSolution::VERSION
  spec.authors = [ 'dhq_boiler' ]
  spec.email = [ 'dhq_boiler@live.jp' ]

  spec.summary = 'Rails engine for image reporting and AI-powered moderation'
  spec.description = 'A complete solution for image reporting, AI-powered moderation using OpenAI Vision API, and admin dashboard for Rails applications with Active Storage.'
  spec.homepage = 'https://github.com/dhq-boiler/rails-image-post-solution'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.4.7'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/dhq-boiler/rails-image-post-solution'
  spec.metadata['changelog_uri'] = 'https://github.com/dhq-boiler/rails-image-post-solution/blob/main/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .github/ .standard.yml])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = [ 'lib' ]

  # Dependencies
  spec.add_dependency 'rails', '>= 8.1'
  spec.add_dependency 'ruby-openai', '~> 6.0'

  # Development dependencies
  spec.add_development_dependency 'factory_bot_rails', '~> 6.0'
  spec.add_development_dependency 'rspec-rails', '~> 6.0'
  spec.add_development_dependency 'sqlite3', '~> 1.4'
end

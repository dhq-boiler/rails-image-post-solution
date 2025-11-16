# frozen_string_literal: true

require_relative "rails_image_post_solution/version"
require_relative "rails_image_post_solution/engine"

module RailsImagePostSolution
  class Error < StandardError; end

  # Configuration
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  class Configuration
    attr_accessor :openai_api_key, :auto_freeze_on_flag, :admin_check_method

    def initialize
      @openai_api_key = ENV["OPENAI_API_KEY"]
      @auto_freeze_on_flag = true
      @admin_check_method = :admin?
    end
  end
end

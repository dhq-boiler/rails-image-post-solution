# frozen_string_literal: true

module RailsImagePostSolution
  class ApplicationController < ::ApplicationController
    # Engine's base controller inherits from host application's ApplicationController
    # This allows the engine to use the host app's authentication methods
  end
end

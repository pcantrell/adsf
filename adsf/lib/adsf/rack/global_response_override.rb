# frozen_string_literal: true

module Adsf::Rack
  class GlobalResponseOverride
    def initialize(app, callback:)
      @app = app
      @callback = callback
    end

    def call(env)
      @callback.call(env) || @app.call(env)
    end
  end
end

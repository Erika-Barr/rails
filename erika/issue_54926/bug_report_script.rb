# frozen_string_literal: true

require "bundler/inline"

gemfile(true) do
  source "https://rubygems.org"

  gem "pry-byebug"
  # TODO: use tag 8.0.1.alpha
  gem "rails", github: "rails/rails", branch: "main"
  # If you want to test against edge Rails replace the previous line with this:
end

require "action_controller/railtie"
require "minitest/autorun"
require "rack/test"

class TestApp < Rails::Application
  config.load_defaults Rails::VERSION::STRING.to_f
  config.root = __dir__
  config.eager_load = false
  config.hosts << "example.org"
  config.secret_key_base = "secret_key_base"

  config.logger = Logger.new($stdout)
end
Rails.application.initialize!

Rails.application.routes.draw do
  get "/", to: "test#index"
end

class TestController < ActionController::Base
  include Rails.application.routes.url_helpers

  def index
    cookies.signed[:foo] = "bar"
    render plain: (cookies.send :signed_cookie_digest)
  end
end

class BugTest < ActiveSupport::TestCase
  include Rack::Test::Methods

  def test_signed_cookies
    get "/"
    assert last_response.ok?
    assert_equal last_response.body, "SHA256"
  end

  private
    def app
      Rails.application
    end
end

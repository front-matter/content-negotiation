require_relative 'boot'

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
# require "active_job/railtie"
# require "active_record/railtie"
require "action_controller/railtie"
# require "action_mailer/railtie"
# require "action_view/railtie"
# require "action_cable/engine"
# require "sprockets/railtie"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# load ENV variables from .env file if it exists
env_file = File.expand_path("../../.env", __FILE__)
if File.exist?(env_file)
  require 'dotenv'
  Dotenv.load! env_file
end

# load ENV variables from container environment if json file exists
# see https://github.com/phusion/baseimage-docker#envvar_dumps
env_json_file = "/etc/container_environment.json"
if File.exist?(env_json_file)
  env_vars = JSON.parse(File.read(env_json_file))
  env_vars.each { |k, v| ENV[k] = v }
end

# default values for some ENV variables
ENV['APPLICATION'] ||= "content-negotiation"
ENV['HOSTNAME'] ||= "data.local"
ENV['MEMCACHE_SERVERS'] ||= "memcached:11211"
ENV['SITE_TITLE'] ||= "Content Resolver"
ENV['LOG_LEVEL'] ||= "info"
ENV['GITHUB_URL'] ||= "https://github.com/crosscite/content-negotiation"
ENV['SEARCH_URL'] ||= "https://search.datacite.org/"
ENV['CITEPROC_URL'] ||= "https://citation.datacite.org/format"
ENV['TRUSTED_IP'] ||= "10.0.0.0/8"

module ContentNegotiation
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    # configure logging
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger = ActiveSupport::TaggedLogging.new(logger)
    config.log_level = ENV['LOG_LEVEL'].to_sym
    config.lograge.enabled = true
    config.lograge.ignore_actions = ['HeartbeatController#index']

    # Make Ruby 2.4 preserve the timezone of the receiver when calling `to_time`.
    # Previous versions had false.
    config.active_support.to_time_preserves_timezone = true

    # Do not halt callback chains when a callback returns false. Previous versions had true.
    config.active_support.halt_callback_chains_on_return_false = false

    # Configure SSL options to enable HSTS with subdomains. Previous versions had false.
    config.ssl_options = { hsts: { subdomains: true } }

    # compress responses with deflate or gzip
    config.middleware.use Rack::Deflater

    # Use memcached as cache store
    config.cache_store = :dalli_store, nil, { expires_in: 7.days }
  end
end

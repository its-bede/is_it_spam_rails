# frozen_string_literal: true

require_relative "is_it_spam_rails/version"
require_relative "is_it_spam_rails/client"
require_relative "is_it_spam_rails/configuration"
require_relative "is_it_spam_rails/controller_extension"
require_relative "is_it_spam_rails/railtie" if defined?(Rails::Railtie)

# Rails integration gem for is-it-spam.com anti-spam service
#
# Provides Rails-specific functionality including:
# - Configuration through Rails initializers
# - Before action hooks for controllers
# - Rails generator for setup
module IsItSpamRails
  class Error < StandardError; end

  # Configuration error raised when credentials are missing or invalid
  class ConfigurationError < Error; end

  # API error raised when the API returns an error response
  class ApiError < Error
    # @return [Integer, nil] HTTP status code
    attr_reader :status_code
    # @return [String, nil] Raw response body
    attr_reader :response_body

    # Initialize API error
    #
    # @param message [String] Error message
    # @param status_code [Integer, nil] HTTP status code
    # @param response_body [String, nil] Raw response body
    def initialize(message, status_code: nil, response_body: nil)
      super(message)
      @status_code = status_code
      @response_body = response_body
    end
  end

  # Rate limit error raised when API rate limits are exceeded
  class RateLimitError < ApiError; end

  # Validation error raised when request parameters are invalid
  class ValidationError < ApiError
    # @return [Hash] Field-specific validation errors
    attr_reader :errors

    # Initialize validation error
    #
    # @param message [String] Error message
    # @param errors [Hash] Field-specific validation errors
    # @param options [Hash] Additional options
    def initialize(message, errors: {}, **options)
      super(message, **options)
      @errors = errors
    end
  end

  # Global configuration for the gem
  #
  # @return [Configuration] The global configuration instance
  def self.configuration
    @configuration ||= Configuration.new
  end

  # Configure the gem with a block
  #
  # @yield [configuration] Configuration block
  # @yieldparam configuration [Configuration] The configuration instance
  def self.configure
    yield(configuration)
  end

  # Get the configured client instance
  #
  # @return [Client] The configured client
  def self.client
    configuration.client
  end

  # Shortcut method for checking spam
  #
  # @param name [String] Name from the contact form
  # @param email [String] Email address from the contact form
  # @param message [String] Message content from the contact form
  # @param custom_fields [Hash] Additional custom fields to check
  # @param end_user_ip [String, nil] IP address of the end user filling the form (optional)
  # @return [SpamCheckResult] The result of the spam check
  def self.check_spam(name:, email:, message:, custom_fields: {}, end_user_ip: nil)
    client.check_spam(name: name, email: email, message: message, custom_fields: custom_fields, end_user_ip: end_user_ip)
  end

  # Check API health
  #
  # @return [Boolean] true if the service is healthy
  def self.health_check
    client.health_check
  end
end

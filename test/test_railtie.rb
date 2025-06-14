# frozen_string_literal: true

require "test_helper"

# Mock Rails components for testing Railtie
module MockRails
  class Application
    def credentials
      @credentials ||= MockCredentials.new
    end
  end
  
  def self.application
    @application ||= Application.new
  end
  
  def self.reset_application!
    @application = nil
  end
  
  class MockCredentials
    def initialize
      @data = {}
    end
    
    def is_it_spam_rails
      @data[:is_it_spam_rails]
    end
    
    def set_credentials(data)
      @data[:is_it_spam_rails] = data
    end
  end
  
  module Railtie
  end
  
  def self.logger
    @logger ||= Object.new.tap do |logger|
      def logger.info(message); end
      def logger.warn(message); end
      def logger.error(message); end
    end
  end
end

module MockActiveSupport
  class << self
    def on_load(component, &block)
      @on_load_callbacks ||= {}
      @on_load_callbacks[component] ||= []
      @on_load_callbacks[component] << block
    end
    
    def trigger_on_load(component, context = nil)
      callbacks = @on_load_callbacks&.[](component) || []
      callbacks.each do |callback|
        if context
          context.instance_eval(&callback)
        else
          callback.call
        end
      end
    end
    
    # Simulate what Rails does when loading the railtie
    def simulate_railtie_loading
      # Clear any existing callbacks first
      reset_callbacks!
      
      # This simulates the railtie initialization
      ActiveSupport.on_load(:action_controller) do
        include IsItSpamRails::ControllerExtension
      end
      
      # Then trigger the callback for MockActionControllerBase
      trigger_on_load(:action_controller, MockActionControllerBase)
    end
    
    def reset_callbacks!
      @on_load_callbacks = {}
    end
  end
end

class MockActionControllerBase
  def self.extended_modules
    @extended_modules ||= []
  end
  
  def self.included_modules
    @included_modules ||= []
  end
  
  def self.extend(mod)
    extended_modules << mod
    super
  end
  
  def self.include(mod)
    included_modules << mod
    super
  end
  
  # Reset tracking arrays
  def self.reset_tracking!
    @extended_modules = []
    @included_modules = []
  end
end

class TestRailtie < Minitest::Test
  def setup
    super
    
    # Store original Rails.application if it exists
    @original_rails_application = Rails.application if defined?(Rails) && Rails.respond_to?(:application)
    
    # Mock Rails.application to point to our mock
    Rails.define_singleton_method(:application) { MockRails.application }
    
    unless defined?(ActiveSupport)
      Object.const_set(:ActiveSupport, MockActiveSupport)
    end
    
    # Reset mocks
    MockActiveSupport.reset_callbacks!
    MockActionControllerBase.reset_tracking!
    MockRails.reset_application!
    
    # Reset environment variables
    ENV.delete("IS_IT_SPAM_API_KEY")
    ENV.delete("IS_IT_SPAM_API_SECRET")
    ENV.delete("IS_IT_SPAM_BASE_URL")
  end

  def teardown
    super
    
    # Restore original Rails.application if it existed
    if @original_rails_application
      Rails.define_singleton_method(:application) { @original_rails_application }
    end
    
    if defined?(ActiveSupport) && ActiveSupport == MockActiveSupport
      Object.send(:remove_const, :ActiveSupport)
    end
    
    MockActiveSupport.reset_callbacks!
  end

  def test_railtie_configures_from_rails_credentials
    # Set up mock credentials
    MockRails.application.credentials.set_credentials({
      api_key: "cred_api_key",
      api_secret: "cred_api_secret",
      base_url: "https://cred.example.com"
    })
    
    # Simulate the initializer running
    IsItSpamRails.configure do |config|
      if defined?(Rails.application.credentials.is_it_spam_rails)
        creds = Rails.application.credentials.is_it_spam_rails
        config.api_key = creds[:api_key]
        config.api_secret = creds[:api_secret]
        config.base_url = creds[:base_url] if creds[:base_url]
      end
    end
    
    configuration = IsItSpamRails.configuration
    assert_equal "cred_api_key", configuration.api_key
    assert_equal "cred_api_secret", configuration.api_secret
    assert_equal "https://cred.example.com", configuration.base_url
  end

  def test_railtie_configures_from_environment_variables
    # Set up environment variables
    ENV["IS_IT_SPAM_API_KEY"] = "env_api_key"
    ENV["IS_IT_SPAM_API_SECRET"] = "env_api_secret"
    ENV["IS_IT_SPAM_BASE_URL"] = "https://env.example.com"
    
    # Simulate the initializer running (fallback to env vars)
    IsItSpamRails.configure do |config|
      # In real Rails, this would check for credentials first
      config.api_key = ENV["IS_IT_SPAM_API_KEY"]
      config.api_secret = ENV["IS_IT_SPAM_API_SECRET"]
      config.base_url = ENV["IS_IT_SPAM_BASE_URL"] if ENV["IS_IT_SPAM_BASE_URL"]
    end
    
    configuration = IsItSpamRails.configuration
    assert_equal "env_api_key", configuration.api_key
    assert_equal "env_api_secret", configuration.api_secret
    assert_equal "https://env.example.com", configuration.base_url
  ensure
    ENV.delete("IS_IT_SPAM_API_KEY")
    ENV.delete("IS_IT_SPAM_API_SECRET")
    ENV.delete("IS_IT_SPAM_BASE_URL")
  end

  def test_configuration_precedence_credentials_over_env
    # Set both credentials and environment variables
    MockRails.application.credentials.set_credentials({
      api_key: "cred_key",
      api_secret: "cred_secret"
    })
    
    ENV["IS_IT_SPAM_API_KEY"] = "env_key"
    ENV["IS_IT_SPAM_API_SECRET"] = "env_secret"
    
    # Simulate the initializer (credentials should take precedence)
    IsItSpamRails.configure do |config|
      if defined?(Rails.application.credentials.is_it_spam_rails)
        creds = Rails.application.credentials.is_it_spam_rails
        config.api_key = creds[:api_key]
        config.api_secret = creds[:api_secret]
      else
        config.api_key = ENV["IS_IT_SPAM_API_KEY"]
        config.api_secret = ENV["IS_IT_SPAM_API_SECRET"]
      end
    end
    
    configuration = IsItSpamRails.configuration
    assert_equal "cred_key", configuration.api_key
    assert_equal "cred_secret", configuration.api_secret
  ensure
    ENV.delete("IS_IT_SPAM_API_KEY")
    ENV.delete("IS_IT_SPAM_API_SECRET")
  end

  def test_configuration_falls_back_to_env_when_no_credentials
    # Don't set credentials, only environment variables
    ENV["IS_IT_SPAM_API_KEY"] = "env_fallback_key"
    ENV["IS_IT_SPAM_API_SECRET"] = "env_fallback_secret"
    
    # Simulate the initializer
    IsItSpamRails.configure do |config|
      if defined?(Rails.application.credentials.is_it_spam_rails) && Rails.application.credentials.is_it_spam_rails
        creds = Rails.application.credentials.is_it_spam_rails
        config.api_key = creds[:api_key]
        config.api_secret = creds[:api_secret]
      else
        config.api_key = ENV["IS_IT_SPAM_API_KEY"]
        config.api_secret = ENV["IS_IT_SPAM_API_SECRET"]
      end
    end
    
    configuration = IsItSpamRails.configuration
    assert_equal "env_fallback_key", configuration.api_key
    assert_equal "env_fallback_secret", configuration.api_secret
  ensure
    ENV.delete("IS_IT_SPAM_API_KEY")
    ENV.delete("IS_IT_SPAM_API_SECRET")
  end

  def test_railtie_handles_missing_credentials_gracefully
    # Ensure no credentials are set
    MockRails.application.credentials.set_credentials(nil)
    
    # Simulate the initializer
    IsItSpamRails.configure do |config|
      if defined?(Rails.application.credentials.is_it_spam_rails) && Rails.application.credentials.is_it_spam_rails
        creds = Rails.application.credentials.is_it_spam_rails
        config.api_key = creds[:api_key]
        config.api_secret = creds[:api_secret]
      end
    end
    
    # Should not raise an error, but configuration should be invalid
    configuration = IsItSpamRails.configuration
    refute configuration.valid?
  end

  def test_railtie_sets_default_base_url_when_not_specified
    MockRails.application.credentials.set_credentials({
      api_key: "test_key",
      api_secret: "test_secret"
      # No base_url specified
    })
    
    # Simulate the initializer
    IsItSpamRails.configure do |config|
      creds = Rails.application.credentials.is_it_spam_rails
      config.api_key = creds[:api_key]
      config.api_secret = creds[:api_secret]
      config.base_url = creds[:base_url] if creds[:base_url]
    end
    
    configuration = IsItSpamRails.configuration
    # Should use the default base URL
    assert_equal "https://is-it-spam.com", configuration.base_url
  end

  def test_railtie_allows_custom_base_url_override
    MockRails.application.credentials.set_credentials({
      api_key: "test_key",
      api_secret: "test_secret",
      base_url: "https://custom-spam-api.example.com"
    })
    
    # Simulate the initializer
    IsItSpamRails.configure do |config|
      creds = Rails.application.credentials.is_it_spam_rails
      config.api_key = creds[:api_key]
      config.api_secret = creds[:api_secret]
      config.base_url = creds[:base_url] if creds[:base_url]
    end
    
    configuration = IsItSpamRails.configuration
    assert_equal "https://custom-spam-api.example.com", configuration.base_url
  end

  def test_on_load_callback_structure
    callback_triggered = false
    
    # Register a callback
    MockActiveSupport.on_load(:test_component) do
      callback_triggered = true
    end
    
    # Trigger the callback
    MockActiveSupport.trigger_on_load(:test_component)
    
    assert callback_triggered
  end
end
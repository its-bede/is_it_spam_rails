# frozen_string_literal: true

require "test_helper"

class TestConfiguration < Minitest::Test
  def test_default_configuration_values
    config = IsItSpamRails::Configuration.new
    
    assert_equal "https://is-it-spam.com", config.base_url
    assert_equal 30, config.timeout
    assert_nil config.api_key
    assert_nil config.api_secret
    # Rails.logger may or may not be available depending on test environment setup
    # We just check that the logger accessor works
    assert_respond_to config, :logger
  end

  def test_configuration_setters_and_getters
    config = IsItSpamRails::Configuration.new
    
    config.api_key = "test_key"
    config.api_secret = "test_secret"
    config.base_url = "https://custom.example.com"
    config.timeout = 60
    
    assert_equal "test_key", config.api_key
    assert_equal "test_secret", config.api_secret
    assert_equal "https://custom.example.com", config.base_url
    assert_equal 60, config.timeout
  end

  def test_valid_returns_true_with_required_credentials
    config = IsItSpamRails::Configuration.new
    config.api_key = "test_key"
    config.api_secret = "test_secret"
    
    assert config.valid?
  end

  def test_valid_returns_false_without_api_key
    config = IsItSpamRails::Configuration.new
    config.api_secret = "test_secret"
    
    refute config.valid?
  end

  def test_valid_returns_false_without_api_secret
    config = IsItSpamRails::Configuration.new
    config.api_key = "test_key"
    
    refute config.valid?
  end

  def test_valid_returns_false_with_empty_api_key
    config = IsItSpamRails::Configuration.new
    config.api_key = ""
    config.api_secret = "test_secret"
    
    refute config.valid?
  end

  def test_valid_returns_false_with_empty_api_secret
    config = IsItSpamRails::Configuration.new
    config.api_key = "test_key"
    config.api_secret = ""
    
    refute config.valid?
  end

  def test_validate_raises_error_without_api_key
    config = IsItSpamRails::Configuration.new
    config.api_secret = "test_secret"
    
    error = assert_raises IsItSpamRails::ConfigurationError do
      config.validate!
    end
    
    assert_equal "API key is required", error.message
  end

  def test_validate_raises_error_without_api_secret
    config = IsItSpamRails::Configuration.new
    config.api_key = "test_key"
    
    error = assert_raises IsItSpamRails::ConfigurationError do
      config.validate!
    end
    
    assert_equal "API secret is required", error.message
  end

  def test_validate_passes_with_valid_credentials
    config = IsItSpamRails::Configuration.new
    config.api_key = "test_key"
    config.api_secret = "test_secret"
    
    # Should not raise an error
    config.validate!
  end

  def test_client_creates_new_client_with_configuration
    config = IsItSpamRails::Configuration.new
    config.api_key = "test_key"
    config.api_secret = "test_secret"
    config.base_url = "https://custom.example.com"
    config.timeout = 45
    
    client = config.client
    
    assert_instance_of IsItSpamRails::Client, client
    # Client internals are tested separately
  end

  def test_client_caches_instance
    config = IsItSpamRails::Configuration.new
    config.api_key = "test_key"
    config.api_secret = "test_secret"
    
    client1 = config.client
    client2 = config.client
    
    assert_same client1, client2
  end

  def test_reset_client_clears_cached_instance
    config = IsItSpamRails::Configuration.new
    config.api_key = "test_key"
    config.api_secret = "test_secret"
    
    client1 = config.client
    config.reset_client!
    client2 = config.client
    
    refute_same client1, client2
  end

  def test_global_configuration_singleton
    config1 = IsItSpamRails.configuration
    config2 = IsItSpamRails.configuration
    
    assert_same config1, config2
    assert_instance_of IsItSpamRails::Configuration, config1
  end

  def test_global_configure_block
    IsItSpamRails.configure do |config|
      config.api_key = "global_key"
      config.api_secret = "global_secret"
      config.timeout = 120
    end
    
    config = IsItSpamRails.configuration
    assert_equal "global_key", config.api_key
    assert_equal "global_secret", config.api_secret
    assert_equal 120, config.timeout
  end

  def test_global_client_method
    create_valid_config(api_key: "global_test_key")
    
    client = IsItSpamRails.client
    assert_instance_of IsItSpamRails::Client, client
  end

  def test_global_check_spam_method
    create_valid_config
    
    stub_api_request(:post, "/api/v1/spam_checks", 
                    response_body: spam_check_response(spam: false, confidence: 0.1))
    
    result = IsItSpamRails.check_spam(
      name: "John Doe",
      email: "john@example.com",
      message: "Test message"
    )
    
    assert_instance_of IsItSpamRails::SpamCheckResult, result
    refute result.spam?
  end

  def test_global_health_check_method
    create_valid_config
    
    stub_api_request(:get, "/up", status: 200)
    
    result = IsItSpamRails.health_check
    assert_equal true, result
  end

  def test_environment_variable_configuration
    # Simulate environment variables
    ENV["IS_IT_SPAM_API_KEY"] = "env_key"
    ENV["IS_IT_SPAM_API_SECRET"] = "env_secret"
    ENV["IS_IT_SPAM_BASE_URL"] = "https://env.example.com"
    
    # This would be called by the Railtie in a real Rails app
    IsItSpamRails.configure do |config|
      config.api_key = ENV["IS_IT_SPAM_API_KEY"]
      config.api_secret = ENV["IS_IT_SPAM_API_SECRET"]
      config.base_url = ENV["IS_IT_SPAM_BASE_URL"]
    end
    
    config = IsItSpamRails.configuration
    assert_equal "env_key", config.api_key
    assert_equal "env_secret", config.api_secret
    assert_equal "https://env.example.com", config.base_url
  ensure
    # Clean up environment variables
    ENV.delete("IS_IT_SPAM_API_KEY")
    ENV.delete("IS_IT_SPAM_API_SECRET")
    ENV.delete("IS_IT_SPAM_BASE_URL")
  end

  def test_configuration_logger_assignment
    require "logger"
    logger = Logger.new($stdout)
    
    config = IsItSpamRails::Configuration.new
    config.logger = logger
    
    assert_same logger, config.logger
  end

  def test_configuration_overwrites_defaults
    config = IsItSpamRails::Configuration.new
    
    # Test default
    assert_equal "https://is-it-spam.com", config.base_url
    
    # Override default
    config.base_url = "https://custom-spam-checker.com"
    assert_equal "https://custom-spam-checker.com", config.base_url
  end

  def test_multiple_configure_calls_accumulate
    IsItSpamRails.configure do |config|
      config.api_key = "first_key"
      config.timeout = 45
    end
    
    IsItSpamRails.configure do |config|
      config.api_secret = "second_secret"
      config.base_url = "https://second.example.com"
    end
    
    config = IsItSpamRails.configuration
    assert_equal "first_key", config.api_key
    assert_equal "second_secret", config.api_secret
    assert_equal 45, config.timeout
    assert_equal "https://second.example.com", config.base_url
  end

  def test_configuration_is_independent_per_instance
    config1 = IsItSpamRails::Configuration.new
    config2 = IsItSpamRails::Configuration.new
    
    config1.api_key = "key1"
    config2.api_key = "key2"
    
    assert_equal "key1", config1.api_key
    assert_equal "key2", config2.api_key
  end
end
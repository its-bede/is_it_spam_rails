# frozen_string_literal: true

require "test_helper"

class TestIsItSpamRails < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::IsItSpamRails::VERSION
  end

  def test_module_constants_are_defined
    assert defined?(IsItSpamRails::Error)
    assert defined?(IsItSpamRails::ConfigurationError)
    assert defined?(IsItSpamRails::ApiError)
    assert defined?(IsItSpamRails::RateLimitError)
    assert defined?(IsItSpamRails::ValidationError)
    assert defined?(IsItSpamRails::Configuration)
    assert defined?(IsItSpamRails::Client)
    assert defined?(IsItSpamRails::ControllerExtension)
  end

  def test_error_class_hierarchy
    assert IsItSpamRails::ConfigurationError < IsItSpamRails::Error
    assert IsItSpamRails::ApiError < IsItSpamRails::Error
    assert IsItSpamRails::RateLimitError < IsItSpamRails::ApiError
    assert IsItSpamRails::ValidationError < IsItSpamRails::ApiError
  end

  def test_api_error_initialization
    error = IsItSpamRails::ApiError.new("Test message", status_code: 400, response_body: "error body")
    
    assert_equal "Test message", error.message
    assert_equal 400, error.status_code
    assert_equal "error body", error.response_body
  end

  def test_validation_error_initialization
    errors = { "email" => ["is invalid"] }
    error = IsItSpamRails::ValidationError.new("Validation failed", errors: errors, status_code: 422)
    
    assert_equal "Validation failed", error.message
    assert_equal errors, error.errors
    assert_equal 422, error.status_code
  end

  def test_global_configuration_method
    config = IsItSpamRails.configuration
    assert_instance_of IsItSpamRails::Configuration, config
  end

  def test_global_configure_method
    IsItSpamRails.configure do |config|
      config.api_key = "test_global_key"
    end
    
    assert_equal "test_global_key", IsItSpamRails.configuration.api_key
  end

  def test_global_client_method_with_configuration
    create_valid_config(api_key: "global_client_key")
    
    client = IsItSpamRails.client
    assert_instance_of IsItSpamRails::Client, client
  end

  def test_global_check_spam_method
    create_valid_config
    
    stub_api_request(:post, "/api/v1/spam_checks", 
                    response_body: spam_check_response(spam: false, confidence: 0.2))
    
    result = IsItSpamRails.check_spam(
      name: "John Doe",
      email: "john@example.com",
      message: "Test message",
      custom_fields: { company: "Test Corp" }
    )
    
    assert_instance_of IsItSpamRails::SpamCheckResult, result
    refute result.spam?
    assert_equal 0.2, result.confidence_score
  end

  def test_global_health_check_method
    create_valid_config
    
    stub_api_request(:get, "/up", status: 200)
    
    result = IsItSpamRails.health_check
    assert_equal true, result
  end

  def test_global_methods_require_configuration
    # Reset configuration to empty state
    IsItSpamRails.instance_variable_set(:@configuration, nil)
    
    error = assert_raises IsItSpamRails::ConfigurationError do
      IsItSpamRails.client
    end
    
    assert_includes error.message, "required"
  end

  def test_module_can_be_required_safely
    # This test ensures that requiring the module doesn't raise any errors
    # and that all necessary files are loaded
    assert defined?(IsItSpamRails)
    assert IsItSpamRails.respond_to?(:configuration)
    assert IsItSpamRails.respond_to?(:configure)
    assert IsItSpamRails.respond_to?(:client)
    assert IsItSpamRails.respond_to?(:check_spam)
    assert IsItSpamRails.respond_to?(:health_check)
  end
end

# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

# Load Rails and required components
require "rails"
require "active_support/all"
require "action_controller"

# Load the gem
require "is_it_spam_rails"

require "minitest/autorun"
require "minitest/mock"
require "webmock/minitest"

# Disable external HTTP requests during tests
WebMock.disable_net_connect!

class Minitest::Test
  # Setup that runs before each test
  def setup
    # Reset global configuration before each test
    IsItSpamRails.instance_variable_set(:@configuration, nil)
    
    # Clear any environment variables that might interfere
    ENV.delete("IS_IT_SPAM_API_KEY")
    ENV.delete("IS_IT_SPAM_API_SECRET")
    ENV.delete("IS_IT_SPAM_BASE_URL")
  end

  # Teardown that runs after each test
  def teardown
    # Reset configuration after each test
    IsItSpamRails.instance_variable_set(:@configuration, nil)
    WebMock.reset!
  end

  private

  # Helper method to create a valid configuration
  #
  # @param overrides [Hash] Configuration values to override
  # @return [IsItSpamRails::Configuration] Configured instance
  def create_valid_config(overrides = {})
    config_values = {
      api_key: "test_api_key",
      api_secret: "test_api_secret",
      base_url: "https://test.example.com",
      timeout: 30
    }.merge(overrides)

    IsItSpamRails.configure do |config|
      config_values.each { |key, value| config.send("#{key}=", value) }
    end

    IsItSpamRails.configuration
  end

  # Helper method to stub HTTP requests
  #
  # @param method [Symbol] HTTP method (:get, :post, etc.)
  # @param path [String] Request path
  # @param response_body [Hash] Response body as hash
  # @param status [Integer] HTTP status code
  # @param headers [Hash] Response headers
  def stub_api_request(method, path, response_body: {}, status: 200, headers: {})
    default_headers = { "Content-Type" => "application/json" }.merge(headers)
    
    WebMock.stub_request(method, "https://test.example.com#{path}")
      .to_return(
        status: status,
        body: response_body.to_json,
        headers: default_headers
      )
  end

  # Helper method to create a spam check result
  #
  # @param spam [Boolean] Whether content is spam
  # @param confidence [Float] Confidence score (0.0-1.0)
  # @param reasons [Array<String>] Spam reasons
  # @return [Hash] API response format
  def spam_check_response(spam: false, confidence: 0.1, reasons: [])
    {
      "spam" => spam,
      "confidence" => confidence,
      "reasons" => reasons
    }
  end

  # Helper method to create a mock spam check result object
  #
  # @param spam [Boolean] Whether content is spam
  # @param confidence_score [Float] Confidence score (0.0-1.0)
  # @param spam_reasons [Array<String>] Spam reasons
  # @return [MockSpamCheckResult] Mock spam check result
  def mock_spam_check_result(spam: false, confidence_score: 0.1, spam_reasons: [])
    MockSpamCheckResult.new(
      spam: spam,
      confidence_score: confidence_score,
      spam_reasons: spam_reasons
    )
  end

  # Helper method to mock IsItSpamRails.check_spam method
  #
  # @param result [MockSpamCheckResult] Result to return
  # @yield Block to execute with mocked check_spam
  def mock_check_spam(result, &block)
    IsItSpamRails.stub :check_spam, result, &block
  end

  # Helper method to create mock Rails controller parameters
  #
  # @param hash [Hash] Parameters hash
  # @return [MockActionControllerParameters] Mock parameters object
  def mock_params(hash)
    MockActionControllerParameters.new(hash)
  end
end

# Mock SpamCheckResult for testing
class MockSpamCheckResult
  attr_reader :spam, :confidence_score, :spam_reasons

  # Initialize mock spam check result
  #
  # @param spam [Boolean] Whether content is spam
  # @param confidence_score [Float] Confidence score (0.0-1.0)
  # @param spam_reasons [Array<String>] Spam reasons (renamed from reasons for API compatibility)
  def initialize(spam: false, confidence_score: 0.1, spam_reasons: [])
    @spam = spam
    @confidence_score = confidence_score
    @spam_reasons = spam_reasons
  end

  # Check if content is spam
  #
  # @return [Boolean] true if spam
  def spam?
    @spam
  end
end

# Mock ActionController::Parameters for testing
class MockActionControllerParameters < Hash
  # Initialize mock parameters
  #
  # @param hash [Hash] Parameters hash
  def initialize(hash = {})
    super()
    hash.each { |k, v| self[k] = v }
  end

  # Access parameters with automatic nesting
  #
  # @param key [Symbol, String] Parameter key
  # @return [Object, MockActionControllerParameters] Parameter value or nested parameters
  def [](key)
    value = super(key)
    if value.is_a?(Hash)
      MockActionControllerParameters.new(value)
    else
      value
    end
  end

  # Check if parameters are present
  #
  # @return [Boolean] true if not empty
  def present?
    !empty?
  end

  # Check if parameters are blank
  #
  # @return [Boolean] true if empty
  def blank?
    empty?
  end
end

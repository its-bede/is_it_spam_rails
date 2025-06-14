# frozen_string_literal: true

require "test_helper"

class TestClient < Minitest::Test
  def setup
    super
    @valid_config = {
      api_key: "test_api_key",
      api_secret: "test_api_secret",
      base_url: "https://test.example.com",
      timeout: 30
    }
  end

  def test_client_initialization_with_valid_credentials
    client = IsItSpamRails::Client.new(**@valid_config)
    
    assert_instance_of IsItSpamRails::Client, client
  end

  def test_client_initialization_without_api_key
    config = @valid_config.dup
    config[:api_key] = nil
    
    error = assert_raises IsItSpamRails::ConfigurationError do
      IsItSpamRails::Client.new(**config)
    end
    
    assert_equal "API key is required", error.message
  end

  def test_client_initialization_without_api_secret
    config = @valid_config.dup
    config[:api_secret] = nil
    
    error = assert_raises IsItSpamRails::ConfigurationError do
      IsItSpamRails::Client.new(**config)
    end
    
    assert_equal "API secret is required", error.message
  end

  def test_client_initialization_with_empty_api_key
    config = @valid_config.dup
    config[:api_key] = ""
    
    error = assert_raises IsItSpamRails::ConfigurationError do
      IsItSpamRails::Client.new(**config)
    end
    
    assert_equal "API key is required", error.message
  end

  def test_client_initialization_with_empty_api_secret
    config = @valid_config.dup
    config[:api_secret] = ""
    
    error = assert_raises IsItSpamRails::ConfigurationError do
      IsItSpamRails::Client.new(**config)
    end
    
    assert_equal "API secret is required", error.message
  end

  def test_client_initialization_with_defaults
    config = @valid_config.dup
    config.delete(:base_url)
    config.delete(:timeout)
    
    client = IsItSpamRails::Client.new(**config)
    
    assert_instance_of IsItSpamRails::Client, client
  end

  def test_check_spam_with_valid_parameters
    client = IsItSpamRails::Client.new(**@valid_config)
    
    response_data = spam_check_response(spam: false, confidence: 0.1, reasons: [])
    stub_api_request(:post, "/api/v1/spam_checks", response_body: response_data)
    
    result = client.check_spam(
      name: "John Doe",
      email: "john@example.com",
      message: "I'm interested in your services."
    )
    
    assert_instance_of IsItSpamRails::SpamCheckResult, result
    refute result.spam?
    assert_equal 0.1, result.confidence_score
    assert_empty result.spam_reasons
  end

  def test_check_spam_with_spam_content
    client = IsItSpamRails::Client.new(**@valid_config)
    
    response_data = spam_check_response(
      spam: true, 
      confidence: 0.95, 
      reasons: ["Contains spam keywords", "Suspicious email domain"]
    )
    stub_api_request(:post, "/api/v1/spam_checks", response_body: response_data)
    
    result = client.check_spam(
      name: "Spammer",
      email: "spam@badsite.com",
      message: "URGENT!!! FREE MONEY!!!"
    )
    
    assert_instance_of IsItSpamRails::SpamCheckResult, result
    assert result.spam?
    assert_equal 0.95, result.confidence_score
    assert_equal 2, result.spam_reasons.length
    assert_includes result.spam_reasons, "Contains spam keywords"
    assert_includes result.spam_reasons, "Suspicious email domain"
  end

  def test_check_spam_with_custom_fields
    client = IsItSpamRails::Client.new(**@valid_config)
    
    response_data = spam_check_response(spam: false, confidence: 0.2)
    stub_api_request(:post, "/api/v1/spam_checks", response_body: response_data)
    
    result = client.check_spam(
      name: "John Doe",
      email: "john@example.com",
      message: "Test message",
      custom_fields: {
        company: "Acme Corp",
        phone: "555-1234"
      }
    )
    
    assert_instance_of IsItSpamRails::SpamCheckResult, result
    
    # Verify the request was made with custom fields
    assert_requested :post, "https://test.example.com/api/v1/spam_checks" do |req|
      body = JSON.parse(req.body)
      additional_fields = body["spam_check"]["additional_fields"]
      additional_fields["company"] == "Acme Corp" && additional_fields["phone"] == "555-1234"
    end
  end

  def test_check_spam_without_name
    client = IsItSpamRails::Client.new(**@valid_config)
    
    error = assert_raises IsItSpamRails::ValidationError do
      client.check_spam(
        name: "",
        email: "john@example.com",
        message: "Test message"
      )
    end
    
    assert_equal "Validation failed", error.message
    assert_includes error.errors[:name], "can't be blank"
  end

  def test_check_spam_without_email
    client = IsItSpamRails::Client.new(**@valid_config)
    
    error = assert_raises IsItSpamRails::ValidationError do
      client.check_spam(
        name: "John Doe",
        email: "",
        message: "Test message"
      )
    end
    
    assert_equal "Validation failed", error.message
    assert_includes error.errors[:email], "can't be blank"
  end

  def test_check_spam_without_message
    client = IsItSpamRails::Client.new(**@valid_config)
    
    error = assert_raises IsItSpamRails::ValidationError do
      client.check_spam(
        name: "John Doe",
        email: "john@example.com",
        message: ""
      )
    end
    
    assert_equal "Validation failed", error.message
    assert_includes error.errors[:message], "can't be blank"
  end

  def test_check_spam_with_invalid_email
    client = IsItSpamRails::Client.new(**@valid_config)
    
    error = assert_raises IsItSpamRails::ValidationError do
      client.check_spam(
        name: "John Doe",
        email: "invalid-email",
        message: "Test message"
      )
    end
    
    assert_equal "Validation failed", error.message
    assert_includes error.errors[:email], "is not a valid email address"
  end

  def test_check_spam_with_multiple_validation_errors
    client = IsItSpamRails::Client.new(**@valid_config)
    
    error = assert_raises IsItSpamRails::ValidationError do
      client.check_spam(
        name: "",
        email: "invalid-email",
        message: ""
      )
    end
    
    assert_equal "Validation failed", error.message
    assert_includes error.errors[:name], "can't be blank"
    assert_includes error.errors[:email], "is not a valid email address"
    assert_includes error.errors[:message], "can't be blank"
  end

  def test_check_spam_handles_401_unauthorized
    client = IsItSpamRails::Client.new(**@valid_config)
    
    stub_api_request(:post, "/api/v1/spam_checks", 
                    status: 401, 
                    response_body: { "error" => "Unauthorized" })
    
    error = assert_raises IsItSpamRails::ApiError do
      client.check_spam(
        name: "John Doe",
        email: "john@example.com",
        message: "Test message"
      )
    end
    
    assert_equal "Unauthorized", error.message
    assert_equal 401, error.status_code
  end

  def test_check_spam_handles_422_validation_error_from_api
    client = IsItSpamRails::Client.new(**@valid_config)
    
    stub_api_request(:post, "/api/v1/spam_checks", 
                    status: 422,
                    response_body: {
                      "error" => "Validation failed",
                      "errors" => { "email" => ["is invalid"] }
                    })
    
    error = assert_raises IsItSpamRails::ValidationError do
      client.check_spam(
        name: "John Doe",
        email: "john@example.com",
        message: "Test message"
      )
    end
    
    assert_equal "Validation failed", error.message
    assert_equal 422, error.status_code
    assert_includes error.errors["email"], "is invalid"
  end

  def test_check_spam_handles_429_rate_limit
    client = IsItSpamRails::Client.new(**@valid_config)
    
    stub_api_request(:post, "/api/v1/spam_checks", 
                    status: 429,
                    response_body: { "error" => "Rate limit exceeded" })
    
    error = assert_raises IsItSpamRails::RateLimitError do
      client.check_spam(
        name: "John Doe",
        email: "john@example.com",
        message: "Test message"
      )
    end
    
    assert_equal "Rate limit exceeded", error.message
    assert_equal 429, error.status_code
  end

  def test_check_spam_handles_500_server_error
    client = IsItSpamRails::Client.new(**@valid_config)
    
    stub_api_request(:post, "/api/v1/spam_checks", 
                    status: 500,
                    response_body: { "error" => "Internal server error" })
    
    error = assert_raises IsItSpamRails::ApiError do
      client.check_spam(
        name: "John Doe",
        email: "john@example.com",
        message: "Test message"
      )
    end
    
    assert_equal "Internal server error", error.message
    assert_equal 500, error.status_code
  end

  def test_health_check_returns_true_when_healthy
    client = IsItSpamRails::Client.new(**@valid_config)
    
    stub_api_request(:get, "/up", status: 200)
    
    result = client.health_check
    assert_equal true, result
  end

  def test_health_check_returns_false_when_service_unavailable
    client = IsItSpamRails::Client.new(**@valid_config)
    
    stub_api_request(:get, "/up", status: 503)
    
    result = client.health_check
    assert_equal false, result
  end

  def test_health_check_raises_error_on_other_errors
    client = IsItSpamRails::Client.new(**@valid_config)
    
    stub_api_request(:get, "/up", status: 500)
    
    assert_raises IsItSpamRails::ApiError do
      client.health_check
    end
  end

  def test_request_includes_proper_headers
    client = IsItSpamRails::Client.new(**@valid_config)
    
    response_data = spam_check_response(spam: false, confidence: 0.1)
    stub_api_request(:post, "/api/v1/spam_checks", response_body: response_data)
    
    client.check_spam(
      name: "John Doe",
      email: "john@example.com",
      message: "Test message"
    )
    
    assert_requested :post, "https://test.example.com/api/v1/spam_checks" do |req|
      req.headers["Content-Type"] == "application/json" &&
      req.headers["X-Api-Key"] == "test_api_key" &&
      req.headers["X-Api-Secret"] == "test_api_secret" &&
      req.headers["User-Agent"]&.include?("IsItSpam Rails Gem")
    end
  end

  def test_request_body_format
    client = IsItSpamRails::Client.new(**@valid_config)
    
    response_data = spam_check_response(spam: false, confidence: 0.1)
    stub_api_request(:post, "/api/v1/spam_checks", response_body: response_data)
    
    client.check_spam(
      name: "John Doe",
      email: "john@example.com",
      message: "Test message",
      custom_fields: { company: "Acme Corp" }
    )
    
    assert_requested :post, "https://test.example.com/api/v1/spam_checks" do |req|
      body = JSON.parse(req.body)
      spam_check = body["spam_check"]
      
      spam_check["name"] == "John Doe" &&
      spam_check["email"] == "john@example.com" &&
      spam_check["message"] == "Test message" &&
      spam_check["additional_fields"]["company"] == "Acme Corp"
    end
  end

  def test_handles_json_parse_error_in_error_response
    client = IsItSpamRails::Client.new(**@valid_config)
    
    # Stub with invalid JSON
    WebMock.stub_request(:post, "https://test.example.com/api/v1/spam_checks")
      .to_return(status: 400, body: "Invalid JSON response")
    
    error = assert_raises IsItSpamRails::ApiError do
      client.check_spam(
        name: "John Doe",
        email: "john@example.com",
        message: "Test message"
      )
    end
    
    assert_equal "API request failed", error.message
    assert_equal 400, error.status_code
  end

  def test_handles_unexpected_status_code
    client = IsItSpamRails::Client.new(**@valid_config)
    
    stub_api_request(:post, "/api/v1/spam_checks", status: 418) # I'm a teapot
    
    error = assert_raises IsItSpamRails::ApiError do
      client.check_spam(
        name: "John Doe",
        email: "john@example.com",
        message: "Test message"
      )
    end
    
    assert_equal "Unexpected response code: 418", error.message
    assert_equal 418, error.status_code
  end
end
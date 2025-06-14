# frozen_string_literal: true

require "httparty"

module IsItSpamRails
  # Main client class for interacting with the Is It Spam API
  #
  # Provides methods for checking spam and communicating with the API
  class Client
    include HTTParty

    # API version
    API_VERSION = "v1"
    # Default timeout for requests
    DEFAULT_TIMEOUT = 30

    # Initialize client with credentials
    #
    # @param api_key [String] Your API key from Is It Spam
    # @param api_secret [String] Your API secret from Is It Spam
    # @param base_url [String] Base URL for the API (default: https://is-it-spam.com)
    # @param timeout [Integer] Request timeout in seconds (default: 30)
    # @raise [ConfigurationError] When credentials are missing
    def initialize(api_key:, api_secret:, base_url: "https://is-it-spam.com", timeout: DEFAULT_TIMEOUT)
      @api_key = api_key
      @api_secret = api_secret
      @base_url = base_url.chomp("/")
      @timeout = timeout

      validate_credentials!

      self.class.base_uri @base_url
      self.class.default_timeout @timeout
    end

    # Check if the provided content is spam
    #
    # @param name [String] Name from the contact form
    # @param email [String] Email address from the contact form
    # @param message [String] Message content from the contact form
    # @param custom_fields [Hash] Additional custom fields to check (optional)
    # @return [SpamCheckResult] The result of the spam check
    # @raise [ValidationError] When required parameters are missing or invalid
    # @raise [ApiError] When the API returns an error
    # @raise [RateLimitError] When rate limits are exceeded
    def check_spam(name:, email:, message:, custom_fields: {})
      validate_required_params(name: name, email: email, message: message)

      payload = {
        spam_check: {
          name: name,
          email: email,
          message: message,
          additional_fields: custom_fields
        }
      }

      response = make_request(:post, "/api/#{API_VERSION}/spam_checks", body: payload.to_json)
      SpamCheckResult.new(response.parsed_response)
    end

    # Check the health of the API service
    #
    # @return [Boolean] true if the service is healthy
    # @raise [ApiError] When the API is unavailable
    def health_check
      make_request(:get, "/up")
      true
    rescue ApiError => e
      raise e unless e.status_code == 503
      false
    end

    private

    # Validate that API credentials are present
    #
    # @raise [ConfigurationError] When credentials are missing
    def validate_credentials!
      raise ConfigurationError, "API key is required" if @api_key.nil? || @api_key.empty?
      raise ConfigurationError, "API secret is required" if @api_secret.nil? || @api_secret.empty?
    end

    # Validate required parameters for spam checking
    #
    # @param name [String] Name parameter
    # @param email [String] Email parameter
    # @param message [String] Message parameter
    # @raise [ValidationError] When parameters are invalid
    def validate_required_params(name:, email:, message:)
      errors = {}

      errors[:name] = ["can't be blank"] if name.nil? || name.empty?
      errors[:email] = ["can't be blank"] if email.nil? || email.empty?
      errors[:message] = ["can't be blank"] if message.nil? || message.empty?

      # Basic email format validation
      if email && !email.match?(/\A[^@\s]+@[^@\s]+\z/)
        errors[:email] = (errors[:email] || []) << "is not a valid email address"
      end

      unless errors.empty?
        raise ValidationError.new("Validation failed", errors: errors)
      end
    end

    # Make an HTTP request to the API
    #
    # @param method [Symbol] HTTP method (:get, :post, etc.)
    # @param path [String] API endpoint path
    # @param options [Hash] Additional request options
    # @return [HTTParty::Response] HTTP response object
    # @raise [ApiError, RateLimitError, ValidationError] Based on response
    def make_request(method, path, **options)
      request_options = {
        headers: {
          "Content-Type" => "application/json",
          "X-API-Key" => @api_key,
          "X-API-Secret" => @api_secret,
          "User-Agent" => "IsItSpam Rails Gem #{IsItSpamRails::VERSION}"
        }
      }.merge(options)

      response = self.class.send(method, path, request_options)
      handle_response(response)
    end

    # Handle API response and raise appropriate errors
    #
    # @param response [HTTParty::Response] HTTP response object
    # @return [HTTParty::Response] Response for successful requests
    # @raise [ApiError, RateLimitError, ValidationError] Based on status code
    def handle_response(response)
      case response.code
      when 200..299
        response
      when 400
        handle_error_response(response, ApiError)
      when 401
        handle_error_response(response, ApiError)
      when 404
        raise ApiError.new("Endpoint not found", status_code: 404, response_body: response.body)
      when 422
        handle_validation_error(response)
      when 429
        handle_error_response(response, RateLimitError)
      when 500..599
        handle_error_response(response, ApiError)
      else
        raise ApiError.new("Unexpected response code: #{response.code}",
                          status_code: response.code,
                          response_body: response.body)
      end
    end

    # Handle error responses with JSON body
    #
    # @param response [HTTParty::Response] HTTP response object
    # @param error_class [Class] Error class to raise
    # @raise [ApiError, RateLimitError] Specified error class
    def handle_error_response(response, error_class)
      begin
        error_data = response.parsed_response
        message = error_data["error"] || "API request failed"
      rescue
        message = "API request failed"
      end

      raise error_class.new(message, status_code: response.code, response_body: response.body)
    end

    # Handle validation error responses
    #
    # @param response [HTTParty::Response] HTTP response object
    # @raise [ValidationError] With field-specific errors
    def handle_validation_error(response)
      begin
        error_data = response.parsed_response
        message = error_data["error"] || "Validation failed"
        errors = error_data["errors"] || {}
      rescue
        message = "Validation failed"
        errors = {}
      end

      raise ValidationError.new(message, errors: errors, status_code: 422, response_body: response.body)
    end
  end

  # Represents the result of a spam check operation
  #
  # Provides convenient methods for accessing spam detection results
  class SpamCheckResult
    # @return [Boolean] Whether content was identified as spam
    attr_reader :spam
    # @return [Float] Confidence score between 0.0 and 1.0
    attr_reader :confidence
    # @return [Array<String>] Reasons why content was flagged as spam
    attr_reader :reasons

    # Initialize spam check result
    #
    # @param data [Hash] Response data from the API
    def initialize(data)
      @spam = data["spam"]
      @confidence = data["confidence"].to_f
      @reasons = (data["reasons"] || []).dup.freeze
    end

    # Check if content was identified as spam
    #
    # @return [Boolean] true if content was identified as spam
    def spam?
      @spam
    end

    # Check if content appears legitimate
    #
    # @return [Boolean] true if content appears legitimate
    def legitimate?
      !spam?
    end

    # Get confidence score
    #
    # @return [Float] Confidence score between 0.0 and 1.0
    def confidence_score
      @confidence
    end

    # Get reasons for spam detection
    #
    # @return [Array<String>] Reasons why content was flagged as spam
    def spam_reasons
      @reasons
    end

    # Get human-readable summary of the result
    #
    # @return [String] Human-readable summary of the result
    def summary
      if spam?
        "Spam detected (#{(@confidence * 100).round(1)}% confidence): #{@reasons.join(', ')}"
      else
        "Content appears legitimate (#{(@confidence * 100).round(1)}% confidence)"
      end
    end

    # Convert result to hash
    #
    # @return [Hash] Hash representation of the result
    def to_h
      {
        spam: @spam,
        confidence: @confidence,
        reasons: @reasons
      }
    end

    # Convert result to JSON
    #
    # @param args [Array] Arguments passed to to_json
    # @return [String] JSON representation of the result
    def to_json(*args)
      to_h.to_json(*args)
    end
  end
end
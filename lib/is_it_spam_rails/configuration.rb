# frozen_string_literal: true

module IsItSpamRails
  # Configuration class for IsItSpamRails gem
  #
  # Handles global configuration settings for the Rails integration
  class Configuration
    # @return [String, nil] API key for authentication
    attr_accessor :api_key
    # @return [String, nil] API secret for authentication
    attr_accessor :api_secret
    # @return [String] Base URL for the API
    attr_accessor :base_url
    # @return [Integer] Request timeout in seconds
    attr_accessor :timeout
    # @return [Logger, nil] Logger instance for debugging
    attr_accessor :logger
    # @return [Boolean] Whether to track end user IP addresses (default: true)
    attr_accessor :track_end_user_ip

    # Initialize configuration with default values
    def initialize
      @base_url = "https://is-it-spam.com"
      @timeout = 30
      @logger = rails_logger
      @track_end_user_ip = true
    end

    # Get configured client instance
    #
    # @return [Client] The configured client
    # @raise [ConfigurationError] When required configuration is missing
    def client
      @client ||= Client.new(
        api_key: api_key,
        api_secret: api_secret,
        base_url: base_url,
        timeout: timeout
      )
    end

    # Reset the client (useful for testing or credential changes)
    def reset_client!
      @client = nil
    end

    # Check if configuration is valid
    #
    # @return [Boolean] true if configuration has required values
    def valid?
      !api_key.nil? && !api_key.empty? &&
        !api_secret.nil? && !api_secret.empty?
    end

    # Validate configuration and raise error if invalid
    #
    # @raise [ConfigurationError] When configuration is invalid
    def validate!
      raise ConfigurationError, "API key is required" if api_key.nil? || api_key.empty?
      raise ConfigurationError, "API secret is required" if api_secret.nil? || api_secret.empty?
    end

    private

    # Get Rails logger if available, nil otherwise
    #
    # @return [Logger, nil] Rails logger or nil
    def rails_logger
      return nil unless defined?(Rails)
      return nil unless Rails.respond_to?(:logger)
      Rails.logger
    rescue
      nil
    end
  end
end
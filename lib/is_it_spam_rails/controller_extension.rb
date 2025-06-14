# frozen_string_literal: true

module IsItSpamRails
  # Controller extension providing spam checking functionality
  #
  # Adds the `is_it_spam` class method to Rails controllers for automatic spam detection
  module ControllerExtension
    extend ActiveSupport::Concern

    module ClassMethods
      # Add spam checking as a before_action
      #
      # @param options [Hash] Configuration options
      # @option options [Hash] :on_spam Options for handling spam detection
      # @option options [String, Proc] :on_spam[:redirect_to] Path to redirect to when spam is detected
      # @option options [String] :on_spam[:notice] Flash notice message to display
      # @option options [String] :on_spam[:alert] Flash alert message to display
      def is_it_spam(options = {})
        on_spam_options = options.delete(:on_spam) || {}
        
        before_action(options) do
          check_for_spam(on_spam_options)
        end
      end
    end

    private

    # Check for spam and handle accordingly
    #
    # @param on_spam_options [Hash] Options for spam handling
    # @return [void]
    def check_for_spam(on_spam_options = {})
      # Extract form parameters - try common nested keys first
      form_params = extract_form_params
      
      # Skip if essential parameters are blank
      return unless form_params[:name].present? && form_params[:email].present? && form_params[:message].present?

      begin
        @spam_check_result = IsItSpamRails.check_spam(
          name: form_params[:name],
          email: form_params[:email],
          message: form_params[:message],
          custom_fields: {}
        )
        
        if @spam_check_result&.spam? && on_spam_options.any?
          handle_spam_detection(on_spam_options)
        end
      rescue IsItSpamRails::ValidationError => e
        Rails.logger&.warn("Spam check validation failed: #{e.message}")
      rescue IsItSpamRails::RateLimitError => e
        Rails.logger&.warn("Spam check rate limit exceeded: #{e.message}")
      rescue IsItSpamRails::ApiError => e
        Rails.logger&.error("Spam check API error: #{e.message}")
      rescue StandardError => e
        Rails.logger&.error("Spam check unexpected error: #{e.message}")
      end
    end

    # Extract form parameters from nested params
    #
    # @return [Hash] Extracted form parameters
    def extract_form_params
      # Try common form parameter keys
      common_keys = [:commission, :contact, :inquiry, :message, :form]
      
      # First try nested parameters
      common_keys.each do |key|
        if params[key].is_a?(ActionController::Parameters)
          nested_params = params[key]
          return {
            name: nested_params[:name] || nested_params[:first_name] || "#{nested_params[:first_name]} #{nested_params[:last_name]}".strip,
            email: nested_params[:email],
            message: nested_params[:message] || nested_params[:body] || nested_params[:content]
          }
        end
      end
      
      # Fallback to direct parameter access
      {
        name: params[:name] || params[:first_name] || "#{params[:first_name]} #{params[:last_name]}".strip,
        email: params[:email],
        message: params[:message] || params[:body] || params[:content]
      }
    end

    # Handle spam detection by redirecting with flash message
    #
    # @param options [Hash] Spam handling options
    # @return [void]
    def handle_spam_detection(options = {})
      redirect_path = options[:redirect_to] || root_path
      redirect_path = redirect_path.call if redirect_path.respond_to?(:call)
      
      flash_options = {}
      flash_options[:notice] = options[:notice] if options[:notice]
      flash_options[:alert] = options[:alert] if options[:alert]
      
      redirect_to redirect_path, flash_options
    end
  end
end
# frozen_string_literal: true

# Configuration for IsItSpamRails gem
# 
# This initializer configures the connection to the is-it-spam.com API
# for automated spam detection in your Rails application.
#
# For more information, visit: https://is-it-spam.com/docs

IsItSpamRails.configure do |config|
  # Your API credentials from is-it-spam.com
  # You can get these from your dashboard at https://is-it-spam.com/dashboard
  
  # Option 1: Use Rails credentials (recommended)
  # Run: rails credentials:edit
  # Add:
  #   is_it_spam_rails:
  #     api_key: your_api_key_here
  #     api_secret: your_api_secret_here
  #     base_url: https://is-it-spam.com  # optional, defaults to production
  #
  # Then uncomment these lines:
  # config.api_key = Rails.application.credentials.is_it_spam_rails[:api_key]
  # config.api_secret = Rails.application.credentials.is_it_spam_rails[:api_secret]
  # config.base_url = Rails.application.credentials.is_it_spam_rails[:base_url] # optional
  
  # Option 2: Use environment variables
  # Set these in your environment:
  # IS_IT_SPAM_API_KEY=your_api_key_here
  # IS_IT_SPAM_API_SECRET=your_api_secret_here
  # IS_IT_SPAM_BASE_URL=https://is-it-spam.com  # optional
  #
  # Then uncomment these lines:
  # config.api_key = ENV["IS_IT_SPAM_API_KEY"]
  # config.api_secret = ENV["IS_IT_SPAM_API_SECRET"]
  # config.base_url = ENV["IS_IT_SPAM_BASE_URL"] # optional
  
  # Option 3: Direct configuration (not recommended for production)
  # config.api_key = "your_api_key_here"
  # config.api_secret = "your_api_secret_here"
  
  # Optional configuration
  # config.base_url = "https://is-it-spam.com"  # API base URL
  # config.timeout = 30                         # Request timeout in seconds
  # config.logger = Rails.logger                # Logger for debugging
end

# Usage in controllers:
#
# class ContactController < ApplicationController
#   # Basic usage - detects spam and redirects with notice
#   check_spam only: :create
#   
#   # Custom configuration
#   check_spam only: :create, 
#              redirect_path: root_path, 
#              notice: "Thank you for your message"
#   
#   # With custom parameter mapping
#   check_spam only: :create,
#              param_key: :contact_form,  # if your params are nested under contact_form
#              custom_fields: {           # map additional fields
#                company: :company_name,
#                phone: :phone_number
#              }
#   
#   def create
#     # Your normal controller logic
#     # Spam checking happens automatically before this action
#     
#     # You can access the spam check result if needed:
#     # @spam_check_result.spam? 
#     # @spam_check_result.confidence_score
#     # @spam_check_result.spam_reasons
#   end
# end
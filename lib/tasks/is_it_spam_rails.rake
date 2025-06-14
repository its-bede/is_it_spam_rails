# frozen_string_literal: true

namespace :is_it_spam do
  desc "Install IsItSpamRails by creating an initializer"
  task :install => :environment do
    Rails::Generators.invoke("is_it_spam_rails:install")
  end

  desc "Test connection to Is It Spam API"
  task :test_connection => :environment do
    begin
      puts "Testing connection to Is It Spam API..."
      
      if IsItSpamRails.configuration.valid?
        result = IsItSpamRails.health_check
        if result
          puts "✅ Connection successful!"
          puts "API Key: #{IsItSpamRails.configuration.api_key[0..7]}..."
          puts "Base URL: #{IsItSpamRails.configuration.base_url}"
        else
          puts "❌ API is not healthy (returned false)"
        end
      else
        puts "❌ Configuration is invalid. Please check your API credentials."
        puts "Current configuration:"
        puts "  API Key: #{IsItSpamRails.configuration.api_key.present? ? '[SET]' : '[NOT SET]'}"
        puts "  API Secret: #{IsItSpamRails.configuration.api_secret.present? ? '[SET]' : '[NOT SET]'}"
        puts "  Base URL: #{IsItSpamRails.configuration.base_url}"
      end
    rescue IsItSpamRails::ConfigurationError => e
      puts "❌ Configuration error: #{e.message}"
    rescue IsItSpamRails::ApiError => e
      puts "❌ API error: #{e.message}"
      puts "Status code: #{e.status_code}" if e.status_code
    rescue StandardError => e
      puts "❌ Unexpected error: #{e.message}"
    end
  end

  desc "Test spam detection with sample data"
  task :test_spam_check => :environment do
    begin
      puts "Testing spam detection with sample data..."
      
      # Test with legitimate content
      puts "\n--- Testing legitimate content ---"
      legitimate_result = IsItSpamRails.check_spam(
        name: "John Doe",
        email: "john@example.com",
        message: "I'm interested in your services. Could you please provide more information?"
      )
      puts "Result: #{legitimate_result.spam? ? 'SPAM' : 'LEGITIMATE'}"
      puts "Confidence: #{(legitimate_result.confidence_score * 100).round(1)}%"
      puts "Reasons: #{legitimate_result.spam_reasons.join(', ')}" if legitimate_result.spam_reasons.any?
      
      # Test with spam content
      puts "\n--- Testing spam content ---"
      spam_result = IsItSpamRails.check_spam(
        name: "Spammer",
        email: "spam@suspicious.com",
        message: "URGENT!!! FREE MONEY!!! Click here now to get rich quick! Act fast!"
      )
      puts "Result: #{spam_result.spam? ? 'SPAM' : 'LEGITIMATE'}"
      puts "Confidence: #{(spam_result.confidence_score * 100).round(1)}%"
      puts "Reasons: #{spam_result.spam_reasons.join(', ')}" if spam_result.spam_reasons.any?
      
      puts "\n✅ Spam detection test completed!"
      
    rescue IsItSpamRails::ConfigurationError => e
      puts "❌ Configuration error: #{e.message}"
    rescue IsItSpamRails::ValidationError => e
      puts "❌ Validation error: #{e.message}"
      puts "Errors: #{e.errors}" if e.errors.any?
    rescue IsItSpamRails::ApiError => e
      puts "❌ API error: #{e.message}"
      puts "Status code: #{e.status_code}" if e.status_code
    rescue StandardError => e
      puts "❌ Unexpected error: #{e.message}"
    end
  end

  desc "Show current configuration"
  task :config => :environment do
    puts "IsItSpamRails Configuration:"
    puts "  API Key: #{IsItSpamRails.configuration.api_key.present? ? IsItSpamRails.configuration.api_key[0..7] + '...' : '[NOT SET]'}"
    puts "  API Secret: #{IsItSpamRails.configuration.api_secret.present? ? '[SET]' : '[NOT SET]'}"
    puts "  Base URL: #{IsItSpamRails.configuration.base_url}"
    puts "  Timeout: #{IsItSpamRails.configuration.timeout} seconds"
    puts "  Valid: #{IsItSpamRails.configuration.valid? ? '✅' : '❌'}"
  end
end
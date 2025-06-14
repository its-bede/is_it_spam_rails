# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Ruby gem that provides Rails integration for the is-it-spam.com anti-spam service. The gem adds `check_spam` before_action hooks to Rails controllers for automatic spam detection.

## Architecture

The gem follows a modular architecture:

- **Core API Client** (`lib/is_it_spam_rails/client.rb`) - HTTP client for is-it-spam.com API
- **Configuration** (`lib/is_it_spam_rails/configuration.rb`) - Handles API credentials and settings
- **Rails Integration** (`lib/is_it_spam_rails/railtie.rb`) - Integrates with Rails through Railtie
- **Controller Extension** (`lib/is_it_spam_rails/controller_extension.rb`) - Adds `check_spam` method to controllers
- **Spam Checker** (`lib/is_it_spam_rails/spam_checker.rb`) - Core spam checking logic
- **Rails Generator** (`lib/generators/is_it_spam_rails/install_generator.rb`) - Creates initializer file

## Commands

### Testing
```bash
rake test                           # Run all tests
rake test test/test_client.rb       # Run specific test file
```

### Development
```bash
bin/setup                          # Install dependencies
bin/console                        # Start interactive console
bundle install                    # Install gem dependencies
```

### Gem Tasks
```bash
rake build                         # Build the gem
rake install                       # Install locally
rake release                       # Release to RubyGems
```

### Rails Integration Testing
```bash
bin/rails is_it_spam:test_connection    # Test API connection
bin/rails is_it_spam:test_spam_check   # Test spam detection
bin/rails is_it_spam:config            # Show configuration
bin/rails is_it_spam:install           # Install initializer
```

## Development Notes

- Uses Minitest for testing with WebMock for HTTP stubbing
- All methods should include YARD documentation
- Classes should have description comments
- Environment variables: `IS_IT_SPAM_API_KEY`, `IS_IT_SPAM_API_SECRET`, `IS_IT_SPAM_BASE_URL`
- Rails credentials path: `is_it_spam_rails.api_key`, `is_it_spam_rails.api_secret`
- Gem supports Rails 6.0+ and Ruby 3.1+
- Uses HTTParty for HTTP requests
- Configuration auto-loads from Rails credentials or environment variables
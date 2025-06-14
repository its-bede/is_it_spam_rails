## [Unreleased]

## [0.1.0] - 2025-06-14

### Added
- Rails integration gem for is-it-spam.com anti-spam service
- `is_it_spam` controller method with before_action hooks
- Manual spam handling mode (returns @spam_check_result for custom handling)
- Automatic spam handling mode with `on_spam` configuration for redirects
- Rails configuration through credentials and environment variables
- HTTP client with comprehensive error handling and rate limiting
- Rails Railtie for automatic controller extension inclusion
- Rails generator for easy setup
- Comprehensive test suite with Rails integration testing
- Support for nested parameter extraction (contact, commission, inquiry forms)
- Configurable API timeouts and base URL
- Rails logger integration for error reporting

### Features
- **Controller Integration**: Simple `is_it_spam only: [:create], on_spam: { redirect_to: root_path, notice: 'message' }` API
- **Flexible Configuration**: Rails credentials, environment variables, or manual configuration
- **Error Handling**: Graceful degradation with proper logging on API failures
- **Rails Native**: Uses ActiveSupport::Concern and Rails conventions
- **Production Ready**: Comprehensive error handling and logging

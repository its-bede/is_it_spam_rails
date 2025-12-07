## [Unreleased]

## [2.0.0] - TBD

### ⚠️ Breaking Changes
- **IP tracking is now ON by default** - The gem automatically captures and sends end user IP addresses (`request.remote_ip`) to the API
  - End user IPs are tracked for spam detection and blocking across all apps
  - To disable: set `config.track_end_user_ip = false` in your initializer
  - Review your privacy policy before upgrading - IP addresses are personal data under GDPR
  - Existing apps upgrading from 0.1.x will start tracking IPs immediately upon deployment

### Added
- **End user IP tracking** - Capture the actual IP address of the person filling out your form
  - New configuration option: `track_end_user_ip` (default: true)
  - Sends `end_user_ip` parameter to API for IP-based spam blocking
  - Enables blocking malicious users across your entire hosting system
  - IP tracking can be disabled per-app via configuration
  - Backward compatible with is-it-spam.com API (falls back to server IP if not provided)

### Changed
- `Client#check_spam` now accepts optional `end_user_ip:` parameter
- `IsItSpamRails.check_spam` module method now accepts optional `end_user_ip:` parameter
- Controller extension automatically captures `request.remote_ip` when tracking is enabled

### Privacy & GDPR
- End user IP addresses are now sent to is-it-spam.com by default
- IPs are stored in spam check logs for spam detection and analytics
- Legal basis: Legitimate interest (spam prevention)
- Users can opt-out with `config.track_end_user_ip = false`
- App owners should update privacy policies to disclose IP tracking

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

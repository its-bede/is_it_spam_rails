# IsItSpamRails

Rails integration gem for [is-it-spam.com](https://is-it-spam.com) anti-spam service. Provides easy-to-use before_action hooks for automatic spam detection in your Rails controllers.

## Installation

Add the gem to your application's Gemfile:

```ruby
gem 'is_it_spam_rails'
```

Then execute:

```bash
$ bundle install
```

Run the installer to create the initializer:

```bash
$ bin/rails is_it_spam:install
```

## Configuration

Configure your API credentials in `config/initializers/is_it_spam_rails.rb`:

### Option 1: Rails Credentials (Recommended)

```bash
$ rails credentials:edit
```

Add your credentials:

```yaml
is_it_spam_rails:
  api_key: your_api_key_here
  api_secret: your_api_secret_here
  base_url: https://is-it-spam.com  # optional
```

Then in your initializer:

```ruby
IsItSpamRails.configure do |config|
  config.api_key = Rails.application.credentials.is_it_spam_rails[:api_key]
  config.api_secret = Rails.application.credentials.is_it_spam_rails[:api_secret]
end
```

### Option 2: Environment Variables

Set environment variables:

```bash
export IS_IT_SPAM_API_KEY=your_api_key_here
export IS_IT_SPAM_API_SECRET=your_api_secret_here
export IS_IT_SPAM_BASE_URL=https://is-it-spam.com  # optional
```

The gem will automatically use these if no explicit configuration is provided.

## Usage

### Basic Usage

Add spam checking to your controllers with the `is_it_spam` method. By default, the gem sets `@spam_check_result` and lets you handle spam detection manually:

```ruby
class ContactController < ApplicationController
  is_it_spam only: [:create]
  
  def create
    # Check if spam was detected
    if @spam_check_result&.spam?
      # Handle spam manually
      flash[:alert] = "Your submission appears to be spam"
      redirect_to root_path
      return
    end
    
    # Process legitimate submissions
    confidence = @spam_check_result&.confidence_score
    Rails.logger.info "Legitimate submission with #{(confidence * 100).round(1)}% confidence"
    # ...
  end
end
```

### Automatic Spam Handling

For automatic spam handling, use the `on_spam` configuration to redirect spam submissions:

```ruby
class ContactController < ApplicationController
  is_it_spam only: [:create], on_spam: {
    redirect_to: root_path,
    notice: 'Thank you for your message'
  }
  
  def create
    # This action only executes for legitimate (non-spam) submissions
    # @spam_check_result is available and will never be spam
    
    # Process the legitimate submission
    # ...
  end
end
```

### Configuration Options

The `on_spam` hash accepts the following options:

```ruby
class ContactController < ApplicationController
  is_it_spam only: [:create], on_spam: {
    redirect_to: root_path,           # Path to redirect on spam detection
    notice: 'Thank you for contacting us'  # Flash notice message
  }
end
```

You can also use `alert` instead of `notice`:

```ruby
class ContactController < ApplicationController
  is_it_spam only: [:create], on_spam: {
    redirect_to: root_path,
    alert: 'There was an issue with your submission'
  }
end
```

### Dynamic Redirect Paths

Use route helpers or callable objects for dynamic paths:

```ruby
class ContactController < ApplicationController
  is_it_spam only: [:create], on_spam: {
    redirect_to: Rails.application.routes.url_helpers.root_path,
    notice: I18n.t('contact.success')
  }
end
```

### Parameter Detection

The gem automatically detects form parameters from common nested keys:
- `:commission`, `:contact`, `:inquiry`, `:message`, `:form`
- Maps `name`, `email`, and `message` fields
- Supports `first_name`/`last_name` combination for name field

## Testing and Debugging

The gem includes rake tasks for testing your configuration:

```bash
# Test API connection
$ bin/rails is_it_spam:test_connection

# Test spam detection with sample data
$ bin/rails is_it_spam:test_spam_check

# Show current configuration
$ bin/rails is_it_spam:config
```

## API

### Direct API Usage

You can also use the API directly without the before_action:

```ruby
result = IsItSpamRails.check_spam(
  name: "John Doe",
  email: "john@example.com", 
  message: "Your message here",
  custom_fields: { company: "Acme Corp" }
)

if result.spam?
  puts "Spam detected: #{result.spam_reasons.join(', ')}"
  puts "Confidence: #{(result.confidence_score * 100).round(1)}%"
else
  puts "Message appears legitimate"
end
```

### Health Check

Check if the API service is available:

```ruby
if IsItSpamRails.health_check
  puts "API is healthy"
else
  puts "API is not responding"
end
```

## Error Handling

The gem is designed to fail gracefully. If the API is unavailable, rate limited, or returns errors, your application will continue to function normally. Errors are logged but don't block legitimate users.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/its-benjamin-deutscher/is-it-spam.com.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
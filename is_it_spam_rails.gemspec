# frozen_string_literal: true

require_relative "lib/is_it_spam_rails/version"

Gem::Specification.new do |spec|
  spec.name = "is_it_spam_rails"
  spec.version = IsItSpamRails::VERSION
  spec.authors = ["Benjamin Deutscher"]
  spec.email = ["ben@bdeutscher.org"]

  spec.summary = "Rails integration for is-it-spam.com anti-spam service"
  spec.description = "Provides Rails integration for the is-it-spam.com API with before_action hooks for automatic spam detection in controllers."
  spec.homepage = "https://is-it-spam.com"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/its-benjamin-deutscher/is-it-spam.com"
  spec.metadata["changelog_uri"] = "https://github.com/its-benjamin-deutscher/is-it-spam.com/blob/main/lib/is_it_spam_rails/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Dependencies
  spec.add_dependency "rails", ">= 6.0"
  spec.add_dependency "httparty", "~> 0.21"
  
  # Development dependencies
  spec.add_development_dependency "webmock", "~> 3.18"
  spec.add_development_dependency "sqlite3", "~> 1.4"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end

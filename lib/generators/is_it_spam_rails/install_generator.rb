# frozen_string_literal: true

require "rails/generators"

module IsItSpamRails
  module Generators
    # Rails generator for installing IsItSpamRails
    #
    # Creates an initializer file with configuration template
    class InstallGenerator < Rails::Generators::Base
      desc "Install IsItSpamRails by creating an initializer"

      # Define source location for templates
      source_root File.expand_path("templates", __dir__)

      # Create the initializer file
      #
      # @return [void]
      def create_initializer
        template "initializer.rb", "config/initializers/is_it_spam_rails.rb"
      end

      # Display installation instructions
      #
      # @return [void]
      def show_instructions
        say ""
        say "IsItSpamRails has been installed!", :green
        say ""
        say "Next steps:"
        say "1. Configure your API credentials in config/initializers/is_it_spam_rails.rb"
        say "2. Add your credentials to Rails credentials or environment variables"
        say "3. Use is_it_spam in your controllers as a before_action"
        say ""
        say "Example usage in a controller:"
        say "  class ContactController < ApplicationController"
        say "    is_it_spam only: [:create], on_spam: {"
        say "      redirect_to: root_path,"
        say "      notice: 'Thank you for your message'"
        say "    }"
        say "  end"
        say ""
        say "For more information, visit: https://is-it-spam.com/docs"
      end
    end
  end
end
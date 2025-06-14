# frozen_string_literal: true

module IsItSpamRails
  # Rails integration through Railtie
  #
  # Automatically configures the gem when Rails loads and adds controller helpers
  class Railtie < Rails::Railtie
    # Add spam checking functionality to ActionController::Base
    initializer "is_it_spam_rails.add_controller_helpers" do
      ActiveSupport.on_load(:action_controller) do
        include IsItSpamRails::ControllerExtension
      end
    end

    # Add rake tasks
    rake_tasks do
      load File.expand_path("../tasks/is_it_spam_rails.rake", __dir__)
    end

    # Add generators
    generators do
      require_relative "../generators/is_it_spam_rails/install_generator"
    end
  end
end
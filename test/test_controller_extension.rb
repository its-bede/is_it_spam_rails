# frozen_string_literal: true

require "test_helper"

# Test controller using real Rails components
class TestController < ActionController::Base
  include IsItSpamRails::ControllerExtension
  
  attr_accessor :spam_check_result_captured, :redirected_to, :flash_captured
  
  def initialize
    super
    @spam_check_result_captured = nil
    @redirected_to = nil
    @flash_captured = {}
  end
  
  # Override redirect_to to capture redirects in tests
  def redirect_to(location, options = {})
    @redirected_to = location
    @flash_captured = options
  end
  
  # Mock action for testing
  def create
    @spam_check_result_captured = @spam_check_result
    "create_action_executed"
  end
  
  # Override params to return test data
  def params
    @test_params ||= ActionController::Parameters.new
  end
  
  def params=(new_params)
    if new_params.is_a?(ActionController::Parameters)
      @test_params = new_params
    else
      @test_params = ActionController::Parameters.new(new_params)
    end
  end
  
  private
  
  def root_path
    "/"
  end
end

class TestControllerExtension < Minitest::Test
  def setup
    super
    @controller = TestController.new
  end

  def test_is_it_spam_adds_before_action
    # Test that the class method exists and can be called
    assert_respond_to TestController, :is_it_spam
    
    # This should not raise an error
    begin
      TestController.is_it_spam only: [:create]
      assert true, "is_it_spam method executed without error"
    rescue => e
      assert false, "is_it_spam method raised error: #{e.message}"
    end
  end

  def test_manual_spam_handling_with_legitimate_content
    legitimate_result = mock_spam_check_result(spam: false, confidence_score: 0.2)
    
    mock_check_spam(legitimate_result) do
      @controller.params = {
        commission: {
          name: "John Doe",
          email: "john@example.com", 
          message: "Legitimate inquiry"
        }
      }
      
      @controller.send(:check_for_spam, {})
      
      # Should set @spam_check_result but not redirect
      assert_equal legitimate_result, @controller.instance_variable_get(:@spam_check_result)
      assert_nil @controller.redirected_to
    end
  end

  def test_manual_spam_handling_with_spam_content
    spam_result = mock_spam_check_result(spam: true, confidence_score: 0.9)
    
    mock_check_spam(spam_result) do
      @controller.params = {
        commission: {
          name: "Spammer",
          email: "spam@bad.com",
          message: "URGENT!!! FREE MONEY!!!"
        }
      }
      
      @controller.send(:check_for_spam, {})
      
      # Should set @spam_check_result but NOT redirect (manual handling)
      assert_equal spam_result, @controller.instance_variable_get(:@spam_check_result)
      assert_nil @controller.redirected_to
    end
  end

  def test_automatic_spam_handling_with_spam_content
    spam_result = mock_spam_check_result(spam: true, confidence_score: 0.95)
    
    mock_check_spam(spam_result) do
      @controller.params = {
        contact: {
          name: "Spammer",
          email: "spam@evil.com", 
          message: "BUY NOW!!! URGENT!!!"
        }
      }
      
      on_spam_options = { redirect_to: "/thanks", notice: "Thank you for your message" }
      @controller.send(:check_for_spam, on_spam_options)
      
      # Should redirect when spam detected with on_spam config
      assert_equal spam_result, @controller.instance_variable_get(:@spam_check_result)
      assert_equal "/thanks", @controller.redirected_to
      assert_equal "Thank you for your message", @controller.flash_captured[:notice]
    end
  end

  def test_automatic_spam_handling_with_alert_message
    spam_result = mock_spam_check_result(spam: true, confidence_score: 0.8)
    
    mock_check_spam(spam_result) do
      @controller.params = {
        inquiry: {
          name: "Bad Actor",
          email: "bad@spam.com",
          message: "Suspicious content"
        }
      }
      
      on_spam_options = { redirect_to: "/error", alert: "There was an issue" }
      @controller.send(:check_for_spam, on_spam_options)
      
      assert_equal "/error", @controller.redirected_to
      assert_equal "There was an issue", @controller.flash_captured[:alert]
    end
  end

  def test_parameter_extraction_with_action_controller_parameters
    legitimate_result = mock_spam_check_result(spam: false)
    
    mock_check_spam(legitimate_result) do
      # Use real ActionController::Parameters
      @controller.params = ActionController::Parameters.new({
        contact: {
          name: "John Doe",
          email: "john@example.com",
          message: "Real Rails parameters test"
        }
      })
      
      @controller.send(:check_for_spam, {})
      
      assert_equal legitimate_result, @controller.instance_variable_get(:@spam_check_result)
    end
  end

  def test_handles_nested_parameters_correctly
    legitimate_result = mock_spam_check_result(spam: false)
    
    # Test different nested parameter structures
    test_cases = [
      { commission: { name: "John", email: "john@test.com", message: "Hello" } },
      { contact: { name: "Jane", email: "jane@test.com", message: "Hi" } },
      { inquiry: { name: "Bob", email: "bob@test.com", message: "Question" } }
    ]
    
    test_cases.each do |params_hash|
      mock_check_spam(legitimate_result) do
        @controller.params = ActionController::Parameters.new(params_hash)
        @controller.send(:check_for_spam, {})
        
        # Should extract parameters and set result
        assert_equal legitimate_result, @controller.instance_variable_get(:@spam_check_result)
      end
    end
  end

  def test_parameter_extraction_with_first_and_last_name
    legitimate_result = mock_spam_check_result(spam: false)
    
    mock_check_spam(legitimate_result) do
      @controller.params = ActionController::Parameters.new({
        contact: {
          first_name: "John",
          last_name: "Doe", 
          email: "john.doe@example.com",
          message: "Test message with separate names"
        }
      })
      
      @controller.send(:check_for_spam, {})
      
      assert_equal legitimate_result, @controller.instance_variable_get(:@spam_check_result)
    end
  end

  def test_skips_check_when_essential_parameters_missing
    @controller.params = ActionController::Parameters.new({
      contact: {
        name: "John Doe",
        email: "", # Missing email
        message: "Test"
      }
    })
    
    @controller.send(:check_for_spam, {})
    
    # Should not call API or set result when essential params missing
    assert_nil @controller.instance_variable_get(:@spam_check_result)
    assert_nil @controller.redirected_to
  end

  def test_error_handling_with_rails_logger
    # Test that Rails.logger is properly used
    original_logger = Rails.logger
    
    # Mock Rails logger to capture log messages
    mock_logger = Object.new
    def mock_logger.warn(message); @warnings ||= []; @warnings << message; end
    def mock_logger.error(message); @errors ||= []; @errors << message; end
    def mock_logger.warnings; @warnings || []; end
    def mock_logger.errors; @errors || []; end
    
    Rails.logger = mock_logger
    
    # Test with API error
    IsItSpamRails.stub :check_spam, ->(*args) { raise IsItSpamRails::ApiError.new("API Error") } do
      @controller.params = ActionController::Parameters.new({
        contact: {
          name: "John Doe",
          email: "john@example.com",
          message: "Test message"
        }
      })
      
      begin
        @controller.send(:check_for_spam, {})
        assert true, "check_for_spam executed without error"
      rescue => e
        assert false, "check_for_spam raised error: #{e.message}"
      end
      
      # Should have logged the error
      assert_includes mock_logger.errors.join, "API Error"
    end
    
    Rails.logger = original_logger
  end

  def test_callable_redirect_path_with_rails_routes
    spam_result = mock_spam_check_result(spam: true)
    
    # Create a callable that mimics Rails route helpers
    custom_path = -> { "/custom/dynamic/path" }
    
    mock_check_spam(spam_result) do
      @controller.params = ActionController::Parameters.new({
        contact: {
          name: "Spammer",
          email: "spam@bad.com",
          message: "SPAM"
        }
      })
      
      on_spam_options = { redirect_to: custom_path, notice: "Thanks" }
      @controller.send(:check_for_spam, on_spam_options)
      
      assert_equal "/custom/dynamic/path", @controller.redirected_to
      assert_equal "Thanks", @controller.flash_captured[:notice]
    end
  end

  def test_concern_inclusion_works_properly
    # Test that ActiveSupport::Concern is working correctly
    assert TestController.included_modules.include?(IsItSpamRails::ControllerExtension)
    
    # Test that class methods are available
    assert_respond_to TestController, :is_it_spam
    
    # Test that instance methods are available (check_for_spam is private)
    controller_instance = TestController.new
    assert controller_instance.respond_to?(:check_for_spam, true), "check_for_spam method should be available as private method"
  end
end
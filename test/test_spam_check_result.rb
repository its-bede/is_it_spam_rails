# frozen_string_literal: true

require "test_helper"

class TestSpamCheckResult < Minitest::Test
  def test_initialization_with_legitimate_result
    data = {
      "spam" => false,
      "confidence" => 0.1,
      "reasons" => []
    }
    
    result = IsItSpamRails::SpamCheckResult.new(data)
    
    assert_equal false, result.spam
    assert_equal 0.1, result.confidence
    assert_equal [], result.reasons
  end

  def test_initialization_with_spam_result
    data = {
      "spam" => true,
      "confidence" => 0.95,
      "reasons" => ["Contains spam keywords", "Suspicious email"]
    }
    
    result = IsItSpamRails::SpamCheckResult.new(data)
    
    assert_equal true, result.spam
    assert_equal 0.95, result.confidence
    assert_equal ["Contains spam keywords", "Suspicious email"], result.reasons
  end

  def test_spam_predicate_method
    legitimate_result = IsItSpamRails::SpamCheckResult.new({"spam" => false, "confidence" => 0.1, "reasons" => []})
    spam_result = IsItSpamRails::SpamCheckResult.new({"spam" => true, "confidence" => 0.9, "reasons" => ["spam"]})
    
    refute legitimate_result.spam?
    assert spam_result.spam?
  end

  def test_legitimate_predicate_method
    legitimate_result = IsItSpamRails::SpamCheckResult.new({"spam" => false, "confidence" => 0.1, "reasons" => []})
    spam_result = IsItSpamRails::SpamCheckResult.new({"spam" => true, "confidence" => 0.9, "reasons" => ["spam"]})
    
    assert legitimate_result.legitimate?
    refute spam_result.legitimate?
  end

  def test_confidence_score_method
    result = IsItSpamRails::SpamCheckResult.new({"spam" => false, "confidence" => 0.42, "reasons" => []})
    
    assert_equal 0.42, result.confidence_score
  end

  def test_spam_reasons_method
    reasons = ["Blocked email", "Contains spam keywords"]
    result = IsItSpamRails::SpamCheckResult.new({"spam" => true, "confidence" => 0.8, "reasons" => reasons})
    
    assert_equal reasons, result.spam_reasons
  end

  def test_summary_for_legitimate_content
    result = IsItSpamRails::SpamCheckResult.new({"spam" => false, "confidence" => 0.15, "reasons" => []})
    
    expected = "Content appears legitimate (15.0% confidence)"
    assert_equal expected, result.summary
  end

  def test_summary_for_spam_content
    result = IsItSpamRails::SpamCheckResult.new({
      "spam" => true, 
      "confidence" => 0.87, 
      "reasons" => ["Spam keywords", "Blocked email"]
    })
    
    expected = "Spam detected (87.0% confidence): Spam keywords, Blocked email"
    assert_equal expected, result.summary
  end

  def test_summary_with_high_precision_confidence
    result = IsItSpamRails::SpamCheckResult.new({"spam" => false, "confidence" => 0.123456, "reasons" => []})
    
    expected = "Content appears legitimate (12.3% confidence)"
    assert_equal expected, result.summary
  end

  def test_to_h_conversion
    data = {
      "spam" => true,
      "confidence" => 0.75,
      "reasons" => ["Suspicious content"]
    }
    result = IsItSpamRails::SpamCheckResult.new(data)
    
    expected_hash = {
      spam: true,
      confidence: 0.75,
      reasons: ["Suspicious content"]
    }
    
    assert_equal expected_hash, result.to_h
  end

  def test_to_json_conversion
    data = {
      "spam" => true,
      "confidence" => 0.75,
      "reasons" => ["Suspicious content"]
    }
    result = IsItSpamRails::SpamCheckResult.new(data)
    
    json_string = result.to_json
    parsed_json = JSON.parse(json_string)
    
    assert_equal true, parsed_json["spam"]
    assert_equal 0.75, parsed_json["confidence"]
    assert_equal ["Suspicious content"], parsed_json["reasons"]
  end

  def test_handles_string_confidence
    # API might return confidence as string
    data = {
      "spam" => false,
      "confidence" => "0.25",
      "reasons" => []
    }
    
    result = IsItSpamRails::SpamCheckResult.new(data)
    
    assert_equal 0.25, result.confidence
    assert_equal 0.25, result.confidence_score
  end

  def test_handles_nil_reasons
    data = {
      "spam" => false,
      "confidence" => 0.1,
      "reasons" => nil
    }
    
    result = IsItSpamRails::SpamCheckResult.new(data)
    
    assert_equal [], result.reasons
    assert_equal [], result.spam_reasons
  end

  def test_handles_missing_reasons_key
    data = {
      "spam" => false,
      "confidence" => 0.1
    }
    
    result = IsItSpamRails::SpamCheckResult.new(data)
    
    assert_equal [], result.reasons
  end

  def test_summary_with_empty_reasons
    result = IsItSpamRails::SpamCheckResult.new({
      "spam" => true, 
      "confidence" => 0.9, 
      "reasons" => []
    })
    
    expected = "Spam detected (90.0% confidence): "
    assert_equal expected, result.summary
  end

  def test_summary_with_single_reason
    result = IsItSpamRails::SpamCheckResult.new({
      "spam" => true, 
      "confidence" => 0.8, 
      "reasons" => ["Blocked email domain"]
    })
    
    expected = "Spam detected (80.0% confidence): Blocked email domain"
    assert_equal expected, result.summary
  end

  def test_confidence_percentage_rounding
    # Test various confidence values and their rounding
    test_cases = [
      [0.123, "12.3"],
      [0.125, "12.5"],
      [0.1234, "12.3"],
      [0.1235, "12.4"],
      [0.999, "99.9"],
      [1.0, "100.0"],
      [0.0, "0.0"]
    ]
    
    test_cases.each do |confidence, expected_percentage|
      result = IsItSpamRails::SpamCheckResult.new({
        "spam" => false, 
        "confidence" => confidence, 
        "reasons" => []
      })
      
      assert_includes result.summary, "#{expected_percentage}% confidence"
    end
  end

  def test_result_immutability
    data = {
      "spam" => true,
      "confidence" => 0.8,
      "reasons" => ["Original reason"]
    }
    
    result = IsItSpamRails::SpamCheckResult.new(data)
    
    # Modify original data
    data["spam"] = false
    data["confidence"] = 0.1
    data["reasons"] << "Added reason"
    
    # Result should remain unchanged
    assert_equal true, result.spam
    assert_equal 0.8, result.confidence
    assert_equal ["Original reason"], result.reasons
    
    # The reasons array should be frozen
    assert result.reasons.frozen?
  end
end
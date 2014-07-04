require 'minitest/autorun'
require_relative '../mas_client'

class TestMasClient < MiniTest::Unit::TestCase
  def setup
    port = ENV['MASPORT'] || 5001
    @client = MasClient.new(port)
    assert_equal @client.port, port
  end

  def test_key
    assert_match /^\d+/, @client.session_key, "good session key"
  end

  def test_symbols
    @client.request_symbols
    symbols = @client.symbols
    assert symbols.length > 0
    # (Assumption: test symbol list always includes ibm.)
    assert (symbols.include? "ibm"), "Missing symbol"
    assert (symbols.include? "jnj"), "Missing symbol"
  end

  def test_indicators
    @client.request_indicators("ibm", MasClient::DAILY)
    indicators = @client.indicators
    assert indicators.length > 0
    sample_indicator1 = "Simple Moving Average"
    sample_indicator2 = "Momentum"
    sample_indicator3 = "MACD Histogram"
    # (Assumption: test indicator list always includes these basic indicators.)
    assert (indicators.include? sample_indicator1), "Missing symbol"
    assert (indicators.include? sample_indicator2), "Missing symbol"
    assert (indicators.include? sample_indicator3), "Missing symbol"
  end

  def test_period_types
    @client.request_period_types("ibm")
    ptypes = @client.period_types
    assert ptypes.length > 0
    assert (ptypes.include? "daily"), "Missing symbol"
    assert (ptypes.include? "weekly"), "Missing symbol"
    assert (ptypes.include? "monthly"), "Missing symbol"
  end

  def test_tradable_data
#    @client.request_tradable_data("food", "weekly")
    @client.request_tradable_data("ibm", "weekly")
    assert @client.tradable_data.length > 0
    data = @client.tradable_data
    first_date = data[0][0]
p "first date: ", first_date
  end
end

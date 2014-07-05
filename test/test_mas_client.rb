require 'minitest/autorun'
require_relative '../mas_client'
require_relative './test_setup'

class InitialSetup
  def initialize
    # Source the .env file to get the $MASPORT env. var.
    source_env_from('./.env')
    mas_script = File::dirname($0) + '/startmas'
    if ! system mas_script; then exit 222 end
    port = ENV['MASPORT'] || 5001
    $client = MasClient.new(port)
    if not $client.logged_in
      puts "Login of client failed - aborting test"
      exit 95
    end
  end
end

sc = InitialSetup.new

class TestMasClient < MiniTest::Unit::TestCase
  def setup
    if not $client.logged_in
      # test_logout has been called - need to re-login:
      InitialSetup.new
    end
  end

  def test_key
    assert_match /^\d+/, $client.session_key, "good session key"
  end

  def test_symbols
    $client.request_symbols
    symbols = $client.symbols
    assert symbols.length > 0
    # (Assumption: test symbol list always includes ibm.)
    assert (symbols.include? "ibm"), "Missing symbol"
    assert (symbols.include? "jnj"), "Missing symbol"
  end

  def test_indicators
    $client.request_indicators("ibm", MasClient::DAILY)
    indicators = $client.indicators
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
    $client.request_period_types("ibm")
    ptypes = $client.period_types
    assert ptypes.length > 0
    assert (ptypes.include? "daily"), "Missing symbol"
    assert (ptypes.include? "weekly"), "Missing symbol"
    assert (ptypes.include? "monthly"), "Missing symbol"
  end

  def test_tradable_data
    ['daily', 'weekly', 'quarterly', 'yearly'].each do |period|
      $client.request_tradable_data("ibm", period)
      assert $client.tradable_data.length > 0
      data = $client.tradable_data
      first_record = data[0]
      assert first_record.length == 6
      assert_match /^\d{8}$/, first_record[0], "date is 8 chars"
      (1..4).each do |i|
        assert_match /^\d+(\.\d+)?$/, first_record[i], "o/h/l/c format"
      end
      assert_match /^\d+$/, first_record[5], "volume is integer"
    end
  end

  def test_indicator_data
    skip
    ['daily', 'weekly', 'quarterly', 'yearly'].each do |period|
      $client.request_indicator_data("ibm", period)
      assert $client.indicator_data.length > 0
      data = $client.indicator_data
      first_record = data[0]
      assert first_record.length == 2
      assert_match /^\d{8}$/, first_record[0], "date is 8 chars"
      assert_match /^\d+(\.\d+)?$/, first_record[1], "float format"
    end
  end

  def test_logout
    $client.logout
  end
end

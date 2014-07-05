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
#    $client.request_tradable_data("food", "weekly")
#    $client.request_tradable_data("ibm", "weekly")
    $client.request_tradable_data("ibm", "daily")
    assert $client.tradable_data.length > 0
    data = $client.tradable_data
    first_record = data[0]
    assert_match /^\d{8}$/, first_record[0], "date is 8 chars"
    (1..4).each do |i|
      assert_match /^\d+(\.\d+)?$/, first_record[i], "o/h/l/c format"
    end
    assert_match /^\D+$/, first_record[5], "volume is integer"
#p "cl.td.class: ", $client.tradable_data.class
#p "cl.td[0].class: ", $client.tradable_data[0].class
#p "cl.td[1].class: ", $client.tradable_data[1].class
#p "cl.td[0]: ", $client.tradable_data[0]
#p "cl: ", $client
#data0 = data[0]
#puts "data0:\n"; p data0
#puts "data1:\n"; p data[1]
#puts "data1:\n"; p data[2]
#    first_date = data[0][0]
#p "first date: ", first_date
#p "first close: ", data[0][4]
#p "first volume: ", data[0][5]
  end

  def test_logout
    $client.logout
#    $client.request_symbols
  end
end

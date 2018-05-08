require 'ruby_contracts'
require 'minitest/autorun'
require_relative './test_setup'


class IndicatorTest < MiniTest::Test
  include TestSetup

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

  def test_check_all_indicators
    $client.request_indicators("ibm", MasClient::DAILY)
    indicators = $client.indicators
    assert indicators.length > 0
    indicators.each do |i|
      assert ! i.empty?, "Emtpy indicator (#{i})"
    end
  end

  def test_indicator_data
    # ('yearly' skipped due to not enough input data.)
    ['daily', 'weekly', 'quarterly'].each do |period|
      $client.request_indicator_data("ibm", 1, period)
      assert $client.indicator_data.length > 0, "#{period} data length"
      data = $client.indicator_data
      first_record = data[0]
      last_record = data[-1]
      [first_record, last_record].each do |record|
        assert record.length == 2
        assert_match(/^\d{8}$/, record[0], "date is 8 chars")
        assert_match(/^\d+(\.\d+)?$/, record[1], "float format")
      end
    end
  end

  def test_indicator_data_with_times
    now = DateTime.now.to_date
    # (+ 1 to make it tomorrow)
    enddt = now + 1
    start_date = enddt - 365*2
    # Test with both a nil and a real end-date.
    [nil, enddt].each do |end_date|
      ['daily', 'weekly'].each do |period|
        $client.request_indicator_data("ibm", 1, period, start_date, end_date)
        assert $client.indicator_data.length > 0, "#{period} data length"
        data = $client.indicator_data
        first_record = data[0]
        last_record = data[-1]
        [first_record, last_record].each do |record|
          assert record.length == 2
          assert_match(/^\d{8}$/, record[0], "date is 8 chars")
          assert_match(/^\d+(\.\d+)?$/, record[1], "float format")
        end
      end
    end
  end

end

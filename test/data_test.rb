require 'ruby_contracts'
require 'minitest/autorun'
require_relative './test_setup'


class DataTest < MiniTest::Test
  include TestSetup

  def test_tradable_data
    ['daily', 'weekly', 'quarterly', 'yearly'].each do |period|
      $client.request_tradable_data("ibm", period)
      assert $client.tradable_data.length > 0
      data = $client.tradable_data
      first_record = data[0]
      last_record = data[-1]
      [first_record, last_record].each do |record|
        assert record.length == 6
        assert_match(/^\d{8}$/, record[0], "date is 8 chars")
        (1..4).each do |i|
          assert_match(/^\d+(\.\d+)?$/, record[i], "o/h/l/c format")
        end
        assert_match(/^\d+$/, record[5], "volume is integer")
      end
    end
  end

  def test_tradable_data_with_times
    now = DateTime.now.to_date
    # (+ 1 to make it tomorrow)
    enddt = now + 1
    start_date = enddt - 365*2
    # Test with both a nil and a real end-date.
    [nil, enddt].each do |end_date|
      ['daily', 'weekly'].each do |period|
        $client.request_tradable_data("ibm", period, start_date, end_date)
        assert $client.tradable_data.length > 0
        data = $client.tradable_data
        first_record = data[0]
        last_record = data[-1]
        [first_record, last_record].each do |record|
          assert record.length == 6
          assert_match(/^\d{8}$/, record[0], "date is 8 chars")
          (1..4).each do |i|
            assert_match(/^\d+(\.\d+)?$/, record[i], "o/h/l/c format")
          end
          assert_match(/^\d+$/, record[5], "volume is integer")
        end
      end
    end
  end

end

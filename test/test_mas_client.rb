require 'minitest/autorun'
require_relative '../mas_client/mas_client'
require_relative '../mas_client/mas_client_optimized'
require_relative './test_setup'
require_relative './tradable_analyzer'

class TradableObjectFactory
  # A new TradableAnalyzer with the specified name and id
  def new_analyzer(name: name, id: id)
    TradableAnalyzer.new(name, id)
  end

  def new_event(name: name, id: id)
    TradableAnalyzer.new(name, id)
  end
end

class InitialSetup
  class MasClientArgs
    def [](key)
      result = HASHTABLE[key]
      if result.nil?
        HASHTABLE.keys.each do |k|
          if k.to_s =~ /#{key}/
            result = HASHTABLE[k]
          end
        end
      end
      result
    end

    HASHTABLE = {
      host: 'localhost', port: ENV['MASPORT'],
      factory: TradableObjectFactory.new, close_after_w: false,
    }
  end

  def initialize
    # Source the .env file to get the $MASPORT env. var.
    testpath = File::dirname($0)
    source_env_from(testpath + '/.env')
    mas_script = testpath + '/startmas'
    if ! system mas_script; then exit 222 end
    port = ENV['MASPORT'] || 5001
    if ENV['OPTIMIZE']
      if verbose then puts "Using MasClientOptimized" end
      $client = MasClientOptimized.new(MasClientArgs.new)
#      $client = MasClientOptimized.new(host: 'localhost', port: port,
#                                       factory: TradableObjectFactory.new)
    else
      if verbose then puts "Using MasClient" end
      $client = MasClient.new(host: 'localhost', port: port,
                                       factory: TradableObjectFactory.new)
    end
    if not $client.logged_in
      puts "Login of client failed - aborting test"
      exit 95
    end
  end
  def verbose
    ENV['VERBOSE']
  end
end

sc = InitialSetup.new
$fin_set = false
SLEEP = true

class TestMasClient < MiniTest::Test
  def setup
    if not $client.logged_in
      # test_logout has been called - must re-login:
      InitialSetup.new
    end
    if not $fin_set
      ObjectSpace.define_finalizer(self, proc {
        if $client.logged_in
          puts "LOGGING OUT"
          # Cleanup
          $client.logout
        end
      })
      $fin_set = true
    end
    if ENV['SLEEP']
      sleep rand
    end
  end

  def verbose
    ENV['VERBOSE']
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
      last_record = data[-1]
      [first_record, last_record].each do |record|
        assert record.length == 6
        assert_match /^\d{8}$/, record[0], "date is 8 chars"
        (1..4).each do |i|
          assert_match /^\d+(\.\d+)?$/, record[i], "o/h/l/c format"
        end
        assert_match /^\d+$/, record[5], "volume is integer"
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
          assert_match /^\d{8}$/, record[0], "date is 8 chars"
          (1..4).each do |i|
            assert_match /^\d+(\.\d+)?$/, record[i], "o/h/l/c format"
          end
          assert_match /^\d+$/, record[5], "volume is integer"
        end
      end
    end
  end

  def test_indicator_data
    # ('yearly' skipped due to not enough input data.)
#    ['daily', 'weekly', 'quarterly', 'yearly'].each do |period|
    ['daily', 'weekly', 'quarterly'].each do |period|
      $client.request_indicator_data("ibm", 1, period)
      assert $client.indicator_data.length > 0, "#{period} data length"
      data = $client.indicator_data
      first_record = data[0]
      last_record = data[-1]
      [first_record, last_record].each do |record|
        assert record.length == 2
        assert_match /^\d{8}$/, record[0], "date is 8 chars"
        assert_match /^\d+(\.\d+)?$/, record[1], "float format"
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
          assert_match /^\d{8}$/, record[0], "date is 8 chars"
          assert_match /^\d+(\.\d+)?$/, record[1], "float format"
        end
      end
    end
  end

  def test_analyzer_list
    $client.request_analyzers("ibm", MasClient::DAILY)
    analyzers = $client.analyzers
    assert analyzers.class == [].class, "analyzers is an array"
    if analyzers.length == 0
      puts "<<<<<No analyzers found>>>>>"
    else
      if verbose
        puts "<<<<<There were #{analyzers.length} analyzers>>>>>"
      end
      analyzers.each do |a|
        assert_kind_of TradableAnalyzer, a
      end
    end
  end

  class PerTypeSpec
    attr_accessor :period_type, :start_date, :end_date
    def initialize(period_type: MasClient::DAILY,
                   start_date: DateTime.now.to_date, end_date: nil)
      local_variables.each do |key|
        value = eval(key.to_s)
        instance_variable_set("@#{key}", value) unless value.nil?
      end
    end
  end

  def test_analysis
    symbol = 'ibm'
    $client.request_analyzers(symbol, MasClient::DAILY)
    selected_analyzers = $client.analyzers[1..6]
    now = DateTime.now
    enddt = Date.new(now.year, now.month, now.day)
    startdt = enddt - 3650
    spec = PerTypeSpec.new(period_type: MasClient::DAILY,
                           start_date: enddt - 960, end_date: enddt)
    $client.set_period_type_spec(spec)
    $client.request_analysis(selected_analyzers, symbol, spec.start_date)
    events = $client.analysis_result
    if events.length > 1
      if verbose
        puts "\n#{events.length} events:"
      end
      events.each do |e|
        if verbose
          puts "<<#{e}>>"
        end
        assert_kind_of TradableEvent, e
      end
    end
    $client.request_analysis(selected_analyzers, symbol, startdt, enddt)
    events = $client.analysis_result
    if events.length > 1
      if verbose
        puts "\nfirst and last (of #{events.length}) events:"
      end
      [events[0], events[-1]].each do |e|
        if verbose
          puts "<<#{e}>>"
        end
        assert_kind_of TradableEvent, e
      end
    end
  end

  def test_logout
    puts "running logout test"
    $client.logout
    assert ! $client.logged_in
  end

end

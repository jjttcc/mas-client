require 'ruby_contracts'
require 'minitest/autorun'
require_relative '../mas_client/mas_client'
require_relative '../mas_client/mas_client_optimized'
require_relative './test_setup'
require_relative './tradable_analyzer'
require_relative '../mas_client/function_parameter'
require_relative '../mas_client/object_spec'

class TradableObjectFactory
  include Contracts::DSL, TimePeriodTypeConstants

  # A new TradableAnalyzer with the specified name and id
  def new_analyzer(name: name, id: id, period_type: period_type)
    TradableAnalyzer.new(name, id, is_intraday(period_type))
  end

  def new_event(date: date, time: time, id: id, type_id: type_id,
                analyzers: analyzers)
    datetime = DateTime.new(date[0..3].to_i, date[4..5].to_i, date[6..7].to_i,
                             time[0..1].to_i, time[2..3].to_i, time[4..5].to_i)
    event_type_id = type_id
    selected_ans = analyzers.select {|a| a.id == id }
    if selected_ans.length == 0
      raise "new_event: id arg, #{id} " +
        "does not identify any known analyzer."
    else
      analyzer = selected_ans[0]
    end
    TradableEvent.new(datetime, event_type_id, analyzer)
  end

  def new_parameter(name: name, type_desc: type_desc, value: value)
    FunctionParameter.new(name, type_desc, value)
  end

end

def new_client
  if ENV['OPTIMIZE']
    if InitialSetup::verbose then puts "Using MasClientOptimized" end
    result = MasClientOptimized.new(InitialSetup::MasClientArgs.new)
  else
    if InitialSetup::verbose then puts "Using MasClient" end
    result = MasClient.new(host: 'localhost', port: port,
                           factory: TradableObjectFactory.new)
  end
  result
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
    $client = new_client
    if not $client.logged_in
      puts "Login of client failed - aborting test"
      exit 95
    end
  end
  def self.verbose
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

  def test_key
    assert_match(/^\d+/, $client.session_key, "good session key")
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

  def test_analyzer_list
    [MasClient::HOURLY, MasClient::DAILY].each do |pt|
      begin
        $client.request_analyzers("ibm", pt)
        analyzers = $client.analyzers
        assert analyzers.class == [].class, "analyzers is an array"
        if analyzers.length == 0
          puts "<<<<<No analyzers found>>>>>"
        else
          if InitialSetup::verbose
            puts "<<<<<There were #{analyzers.length} analyzers>>>>>"
          end
          analyzers.each do |a|
            assert_kind_of TradableAnalyzer, a
            if InitialSetup::verbose then puts a.inspect end
          end
        end
      rescue => e
        puts "e: #{e}"
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
    events = $client.analysis_data
    if events.length > 1
      if InitialSetup::verbose
        puts "\n#{events.length} events:"
      end
      events.each do |e|
        if InitialSetup::verbose
          puts "<<#{e}>>"
        end
        assert_kind_of TradableEvent, e
      end
    end
    $client.request_analysis(selected_analyzers, symbol, startdt, enddt)
    events = $client.analysis_data
    if events.length > 1
      if InitialSetup::verbose
        puts "\nfirst and last (of #{events.length}) events:"
      end
      [events[0], events[-1]].each do |e|
        if InitialSetup::verbose
          puts "<<#{e}>>"
        end
        assert_kind_of TradableEvent, e
      end
    end
  end

  def test_indicator_parameters
    symbol = 'ibm'
    $client.request_indicators(symbol, MasClient::DAILY)
    indicators = $client.indicators
    assert indicators.length > 0
    indicators.each do |i|
      $client.request_indicator_parameters(i)
      $client.indicator_parameters.each do |p|
        if InitialSetup::verbose
          puts "#{p.value} [#{p.type_desc}, #{p.name}]"
        end
        assert p.valid?, "param #{p.inspect} is valid"
      end
    end
  end

  def test_indicator_parameters_modification
    $client.request_indicators("ibm", MasClient::DAILY)
    indicators = $client.indicators
    ind_name = 'MACD Difference'
    macd_diff_idx = 3
    start_date = DateTime.new(2012, 01, 01)
    end_date = DateTime.new(2014, 07, 01)
    assert indicators[macd_diff_idx - 1] == ind_name, 'correct indicator'
    #<ind-name>\t<param-idx1>:<value1>,<param-idx2>:<value2>...
    ['daily'].each do |period|
      $client.request_indicator_parameters_modification(ind_name, "1:5,2:13")
      $client.request_indicator_data("ibm", macd_diff_idx, period,
                                     start_date, end_date)
      data1 = $client.indicator_data

      $client.request_indicator_parameters_modification(ind_name, "1:13,2:26")
      $client.request_indicator_data("ibm", macd_diff_idx, period,
                                     start_date, end_date)
      data2 = $client.indicator_data
      assert data1 != data2, 'result of different params not equal'

      $client.request_indicator_parameters_modification(ind_name, "1:29,2:47")
      $client.request_indicator_data("ibm", macd_diff_idx, period,
                                     start_date, end_date)
      data3 = $client.indicator_data
      assert data1 != data3, 'result of different params not equal[2]'
    end
  end

  def test_indicator_parameters_modification2
    # (Log 2 clients in, set different parameter-settings for same
    # indicator, request param settings and indicator data and verify that
    # the 2 clients don't step on each other - they each use the correct
    # parameter settings.)
    symbol = 'ibm'
    $client1 = new_client
    $client2 = new_client
    $client1.request_indicators(symbol, MasClient::DAILY)
    $client2.request_indicators(symbol, MasClient::DAILY)
    indicators1 = $client1.indicators
    indicators2 = $client2.indicators
    assert indicators1 == indicators2, 'ind lists equal'
    ind_name = 'MACD Difference'
    macd_diff_idx = 3
    start_date = DateTime.new(2012, 01, 01)
    end_date = DateTime.new(2014, 07, 01)
    assert indicators1[macd_diff_idx - 1] == ind_name, 'correct indicator [1]'
    assert indicators2[macd_diff_idx - 1] == ind_name, 'correct indicator [2]'
    ['daily'].each do |period|
      $client1.request_indicator_parameters_modification(ind_name, "1:5,2:13")
      $client1.request_indicator_data(symbol, macd_diff_idx, period,
                                     start_date, end_date)
      $client2.request_indicator_parameters_modification(ind_name, "1:21,2:55")
      $client2.request_indicator_data(symbol, macd_diff_idx, period,
                                     start_date, end_date)
      cl2data = $client2.indicator_data
      cl1data = $client1.indicator_data
      assert cl1data != cl2data, 'cl1/cl2 data should differ'
      # Test that client2's parameters don't step on client1's parameters.
      $client1.request_indicator_data(symbol, macd_diff_idx, period,
                                     start_date, end_date)
      cl1data_II = $client1.indicator_data
      assert cl1data == cl1data_II, 'cl1 vs cl1-later data should NOT differ'
      $client2.request_indicator_data(symbol, macd_diff_idx, period,
                                     start_date, end_date)
      cl2data_II = $client2.indicator_data
      assert cl2data == cl2data_II, 'cl2 vs cl2-later data should NOT differ'
      assert cl1data_II != cl2data_II, 'cl1-later vs cl2-later differ'
    end
  end

  def test_analyzer_parameters
    symbol = 'ibm'
    $client.request_analyzers(symbol, MasClient::DAILY)
    analyzers = $client.analyzers
    assert analyzers.length > 0
    analyzers.each do |a|
      $client.request_analysis_parameters(a.name)
      $client.analysis_parameters.each do |p|
        if InitialSetup::verbose
          puts "#{p.value} [#{p.type_desc}, #{p.name}]"
        end
        assert p.valid?, "param #{p.inspect} is valid"
      end
    end
  end

  def test_analyzer_parameters_modification
    symbol = 'ibm'
    $client.request_analyzers(symbol, MasClient::DAILY)
    analyzers = $client.analyzers
    ana_name = 'Slope of MACD Signal Line Cross Above 0 (Buy)'
    slope_macd_sl0_idx = 5
    start_date = DateTime.new(2012, 01, 01)
    end_date = DateTime.new(2014, 07, 01)
    # Note the "- 1", due to the MAS interface using indexes starting at 1:
    selected = [analyzers[slope_macd_sl0_idx - 1]]
    assert selected[0].name == ana_name, 'correct analyzer'
    ['daily'].each do |period_type|
      $client.request_analysis_parameters_modification(ana_name, "2:3,3:19")
      do_analysis(symbol, period_type, selected, start_date, end_date)
      data1 = $client.analysis_data
      count1 = data1.count

      $client.request_analysis_parameters_modification(ana_name, "2:13,3:26")
      do_analysis(symbol, period_type, selected, start_date, end_date)
      data2 = $client.analysis_data
      count2 = data2.count
      assert data1 != data2, 'result of different params not equal'
      assert data1[0] != data2[0], 'first event not equal [1 vs 2]'
      assert count1 != count2, 'counts not equal [1 vs 2]'

      $client.request_analysis_parameters_modification(ana_name, "2:39,3:97")
      do_analysis(symbol, period_type, selected, start_date, end_date)
      data3 = $client.analysis_data
      count3 = data3.count
      assert data1 != data3, 'result of different params not equal[2]'
      assert data1[0] != data3[0], 'first event not equal [1 vs 3]'
      assert count1 != count3, 'counts not equal [1 vs 3]'
    end
  end

  def test_analyzer_parameters_modification2
    symbol = 'ibm'
    # (Log 2 clients in, set different parameter-settings for the same
    # analyzer, request param settings and analyzer data and verify that
    # the 2 clients don't step on each other - they each use the correct
    # parameter settings.)
    $client1 = new_client
    $client2 = new_client
    $client1.request_analyzers(symbol, MasClient::DAILY)
    $client2.request_analyzers(symbol, MasClient::DAILY)
    analyzers1 = $client1.analyzers
    analyzers2 = $client2.analyzers
    assert analyzers1.count == analyzers2.count, 'analyzer lists counts equal'
    for i in 0..analyzers1.count-1 do
      assert analyzers1[i].name == analyzers2[i].name,
        'analyzer lists: names equal'
      assert analyzers1[i].id == analyzers2[i].id,
        'analyzer lists: ids equal'
    end

    ana_name = 'Slope of MACD Signal Line Cross Above 0 (Buy)'
    slope_macd_sl0_idx = 5
    start_date = DateTime.new(2012, 01, 01)
    end_date = DateTime.new(2014, 07, 01)
    # Note the "- 1", due to the MAS interface using indexes starting at 1:
    selected = [analyzers2[slope_macd_sl0_idx - 1]]
    assert selected[0].name == ana_name, 'correct analyzer'

    ['daily'].each do |period_type|
      $client1.request_analysis_parameters_modification(ana_name, "2:5,3:13")
      do_analysis(symbol, period_type, selected, start_date, end_date, $client1)
      $client2.request_analysis_parameters_modification(ana_name, "2:27,3:43")
      do_analysis(symbol, period_type, selected, start_date, end_date, $client2)
      cl2data = $client2.analysis_data
      cl1data = $client1.analysis_data
      assert cl1data != cl2data, 'cl1/cl2 data should differ'
      assert cl1data[0] != cl2data[0], 'cl1[0]/cl2[0] data should differ'
      assert cl1data.count != cl2data.count, 'cl1/cl2 counts should differ'
      # Test that client2's parameters don't step on client1's parameters.
      do_analysis(symbol, period_type, selected, start_date, end_date, $client1)
      cl1data_II = $client1.analysis_data
      do_analysis(symbol, period_type, selected, start_date, end_date, $client2)
      cl2data_II = $client2.analysis_data
      assert cl1data_II != cl2data_II, 'cl1-later vs cl2-later differ'
      assert cl2data_II[0].datetime != cl1data_II[0].datetime,
        'first event not equal'
      assert cl2data_II[-1].datetime != cl1data_II[-1].datetime,
        'last event not equal'
      assert cl1data.count == cl1data_II.count, 'cl1 - consitent counts'
      assert cl2data_II.count != cl1data_II.count, 'cl1 vs cl2 - counts differ'
      assert cl2data.count == cl2data_II.count, 'cl2 - consitent counts'

      (0..cl1data.count-1).each do |j|
        assert cl1data[j].datetime == cl1data_II[j].datetime, 'same times 1'
        assert cl1data[j].event_type_id == cl1data_II[j].event_type_id,
          'same event_type_ids 1'
        assert cl1data[j].event_type == cl1data_II[j].event_type,
          'same event_types 1'
        assert cl1data[j].analyzer.name == cl1data_II[j].analyzer.name,
          'same ana-names 1'
        assert cl1data[j].analyzer.id == cl1data_II[j].analyzer.id,
          'same ana-ids 1'
      end
      (0..cl2data.count-1).each do |j|
        assert cl2data[j].datetime == cl2data_II[j].datetime, 'same times 2'
        assert cl2data[j].event_type_id == cl2data_II[j].event_type_id,
          'same event_type_ids 2'
        assert cl2data[j].event_type == cl2data_II[j].event_type,
          'same event_types 2'
        assert cl2data[j].analyzer.name == cl2data_II[j].analyzer.name,
          'same ana-names 2'
        assert cl2data[j].analyzer.id == cl2data_II[j].analyzer.id,
          'same ana-ids 2'
      end
    end
  end

  def test_object_info_indicators
    do_test_object_info('indicator')
  end

  def test_object_info_analyzers
    do_test_object_info('event-generator')
  end

  def do_test_object_info(object_type, report = false)
    if object_type != 'indicator' and object_type != 'event-generator'
      raise "Wrong object type: #{object_type}"
    end
    symbol = 'ibm'
    opts = ['', 'debug', 'html', 'debug;html', 'recursive;html',
      'debug;recursive;html', 'debug;recursive', 'recursive',
      'full-recursion;html', 'debug;full-recursion;html',
      'debug;full-recursion', 'full-recursion', ]
    obj_names = []
    if object_type == 'indicator'
      $client.request_indicators(symbol, MasClient::DAILY)
      obj_names = $client.indicators
    else
      $client.request_analyzers(symbol, MasClient::DAILY)
      obj_names = $client.analyzers.map {|a| a.name}
    end
    debug_recurs_sz, debug_sz, no_opt_sz, recurs_sz, full_recurs_sz,
      debug_full_recurs_sz = 0, 0, 0, 0, 0, 0
    opts.each do |o|
      objspecs = []
      obj_names.each do |name|
        objspecs << ObjectSpec.new(object_type, name, o)
      end
      $client.request_object_info(objspecs)
      obj_info = $client.object_info
      assert obj_info.count == obj_names.count,
        "oi count: #{obj_info.count}, objcount: #{obj_names.count}"
      (0..obj_names.count-1).each do |i|
        assert obj_info[i].include?(obj_names[i]),
          "<<<#{obj_info[i]}>>>\n should match <<<#{obj_names[i]}>>>"
      end
      case o
      when 'debug;recursive'
        debug_recurs_sz = obj_info[2].length
      when 'debug'
        debug_sz = obj_info[2].length
      when ''
        no_opt_sz = obj_info[2].length
      when 'recursive'
        recurs_sz = obj_info[2].length
      when 'full-recursion'
        full_recurs_sz = obj_info[2].length
      when 'debug;full-recursion'
        debug_full_recurs_sz = obj_info[2].length
      end
      if report
        $client.object_info.each do |oi|
          puts oi
        end
      end
    end
    assert no_opt_sz < debug_sz, "#{no_opt_sz}, #{debug_sz}"
    assert debug_sz < debug_recurs_sz, "#{debug_sz}, #{debug_recurs_sz}"
    assert recurs_sz < debug_recurs_sz, "#{recurs_sz}, #{debug_recurs_sz}"
    assert recurs_sz < full_recurs_sz, "#{recurs_sz}, #{full_recurs_sz}"
    assert debug_recurs_sz < debug_full_recurs_sz,
      "#{debug_recurs_sz}, #{debug_full_recurs_sz}"
  end

  def test_logout
    puts "running logout test"
    $client.logout
    assert ! $client.logged_in
  end

  def do_analysis(symbol, period_type, selected_analyzers, startdt, enddt,
                 client = $client)
    events = client.analysis_data
    client.request_analysis(selected_analyzers, symbol, startdt, enddt)
    events = client.analysis_data
    if events.length > 1
      if InitialSetup::verbose
        puts "\n#{events.length} events:"
      end
      events.each do |e|
        if InitialSetup::verbose
          puts "<<#{e}>>"
        end
        assert_kind_of TradableEvent, e
      end
    end
  end

end

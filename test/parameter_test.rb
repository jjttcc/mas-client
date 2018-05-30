require 'ruby_contracts'
require 'minitest/autorun'
require_relative './test_setup'
require_relative './analysis_oracle'

# NOTE: Some of these tests are unstable because the source (stock) data
# is not "locked down" - i.e., it could change and thus change the test
# results as a consequence.
class ParameterTest < MiniTest::Test
  include TestSetup
  include ParameterTestTools

  def test_check_all_indicator_parameters
    try_to_fail = true
    # Use this to isolate one indicator (e.g.,
    # "Trend" for "Slope of MACD Signal Line Trend"):
    target_pattern = ""
    $client.request_indicators("ibm", MasClient::DAILY)
    failures = []
    indicators = $client.indicators
    assert indicators.length > 0
    indicators.each do |i|
      if i =~ /#{target_pattern}/ then
        verbose_report "<<<current indicator: #{i}>>>"
        $client.request_indicator_parameters(i)
        if $client.server_error then
          msg = "#{$client.last_error_msg}"
          verbose_report msg
          failures << msg
        else
          parameters = $client.indicator_parameters
          if parameters.count == 0 then verbose_report "#{i} has 0 params" end
          $client.indicator_parameters.each do |p|
            verbose_report "#{p.value} [#{p.type_desc}, #{p.name}]"
          end
          dups = duplicate_names(parameters, InitialSetup::verbose)
          if dups.count > 0 then
            failures << i + ":\n" + dups.keys.inject("")do |result,x|
              "#{result}\n#{x.name}: #{dups[x]} occurrences"
            end
            verbose_report "(dups for #{i}:"
            dups.keys.each do |dup|
              verbose_report "#{dup.name}: #{dups[dup]}"
            end
            verbose_report ")"
          end
        end
      end
    end
    if try_to_fail then
      assert failures.empty?, "duplicate parameter names:\n" +
        failures.join("\n")
    else
      if ! failures.empty? then
        verbose_report "duplicate parameter names:\n" + failures.join("\n")
      end
    end
  end

  def test_check_all_analyzer_parameters
    $client.request_analyzers("ibm", MasClient::DAILY)
    failures = []
    analyzers = $client.analyzers
    assert analyzers.length > 0
    analyzers.each do |a|
      $client.request_analysis_parameters(a.name, DAILY_PERIOD_TYPE)
      if $client.server_error then
        msg = "#{$client.last_error_msg}"
        verbose_report msg
        failures << msg
      else
        parameters = $client.analysis_parameters
        if parameters.count == 0 then
          verbose_report "#{a.name} has 0 params"
        end
        if InitialSetup::verbose then
          parameters.each do |p|
            puts "#{p.value} [#{p.type_desc}, #{p.name}]"
          end
        end
        dups = duplicate_names(parameters, InitialSetup::verbose)
        if dups.count > 0 then
          failures << a.name + ":\n" + dups.keys.inject("")do |result,x|
            "#{result}\n#{x.name}: #{dups[x]} occurrences"
          end
          verbose_report "(dups for #{a.name}:"
          dups.keys.each do |dup|
            verbose_report "#{dup.name}: #{dups[dup]}"
          end
          verbose_report ")"
        end
      end
    end
    assert failures.empty?, "duplicate parameter names:\n" +
      failures.join("\n")
  end

  def test_slope_of_macd_signal_line_trend
    indname = "Slope of MACD Signal Line Trend"
    dups_not_shared = true
    seqnum_for = {}
    $client.request_indicator_parameters(indname)
    parameters = $client.indicator_parameters
    assert parameters.count > 0, "#{indname} NOT have 0 params"
    i = 1
    parameters.each do |p|
      seqnum_for[p] = i
      verbose_report "#{p.value} [#{p.type_desc}, #{p.name}]"
      i += 1
    end
    # Find the duplicates.
    dups = duplicate_names(parameters, InitialSetup::verbose)
    param_report = lambda do |p|
      if InitialSetup::verbose then
        rep = "val: #{p.value.rjust(2, " ")}, name: #{p.name}"
        if dups[p] then
          rep += ", dups: #{dups[p]}"
        end
        $stderr.puts rep
      end
    end
    parameters.each { |p| param_report.call(p) }
    if dups.count > 0 then
      pick = dups.count / 2
      target = dups.keys[pick]
      seqnum = seqnum_for[target]
      newvalue = target.value.to_i + 1
      verbose_report "Changing param with dup'd name (to #{newvalue}):"
      param_report.call(target)
      settings = "#{seqnum}:#{newvalue}"
      $client.request_indicator_parameters_modification(indname, settings)
      $client.request_indicator_parameters(indname)
      newparams = $client.indicator_parameters
      assert newparams.count > 0, "#{indname} NOT have 0 params"
      newtarget = newparams[seqnum-1] # (-1: adjust seqnum to array index)
      verbose_report "<<<THE TARGET/CHANGED ID/PARAM/VALUE: " +
        "#{seqnum}/#{newtarget.name}/#{newtarget.value}>>>"
      assert newtarget.value == newvalue.to_s,
        "New value set (#{newvalue} vs #{newtarget.value})"
      i = 1
      newparams.each do |p|
        verbose_report "#{p.value} [#{p.type_desc}, #{p.name}]"
        if i != seqnum_for[target] && p.name == target.name then
          if dups_not_shared then
            assert p.value != newtarget.value, "Dup'd params should differ " +
              " now (#{p.value}/#{newtarget.value})\n" +
              "(#{p.name}/#{newtarget.name})"
          else
            assert p.value == newtarget.value, "Dup'd params should NOT " +
              "differ now" + " (#{p.value}/" +
              "#{newtarget.value})\n(#{p.name}/#{newtarget.name})"
          end
        end
        i += 1
      end
      verbose_report "New params report, after the change:"
      newparams.each { |p| param_report.call(p) }
    end
    nondups = parameters.find_all do |p|
      ! dups[p]
    end
    # Test/change nonduped param values.
    (0..nondups.count-1).each do |i|
      curp = nondups[i]
      seqn = seqnum_for[curp]
      newvalue = curp.value.to_i + 1 + i
      settings = "#{seqn}:#{newvalue.to_s}"
      verbose_report "reqindparmod with: #{indname}, #{settings}"
      $client.request_indicator_parameters_modification(indname, settings)
      $client.request_indicator_parameters(indname)
      newparams = $client.indicator_parameters
      assert newparams.count > 0, "#{indname} NOT have 0 params"
    end
    assert nondups.count > 0, "nondups.count > 0:" +
      nondups.inject(""){|result,x| "#{result}\n#{x.name}:#{x.value}" }
    assert dups.count == 0, "#{dups.count} duplicate parameter names:\n" +
      dups.keys.inject(""){|result,x| "#{result}\n#{x.name}:#{dups[x]}" }
  end

  def test_slope_of_macd_signal_line_trend_server_bug
    indname = "Slope of MACD Signal Line Trend"
    hosemas = ! ENV['HOSEMAS'].nil?
    if hosemas then verbose_report "Attempting to HOSE MAS server!" end
    seqnum_for = {}
    $client.request_indicator_parameters(indname)
    parameters = $client.indicator_parameters
    assert parameters.count > 0, "#{indname} NOT have 0 params"
    i = 1
    parameters.each do |p|
      seqnum_for[p] = i
      i += 1
    end
    # Find the duplicates.
    dups = duplicate_names(parameters, InitialSetup::verbose)
    nondups = parameters.find_all { |p| ! dups[p] }
    # Test/change nonduped param values.
    (0..nondups.count-1).each do |i|
      curp = nondups[i]
      seqn = seqnum_for[curp]
      newvalue = curp.value.to_i + 1 + i
      verbose_report "Setting #{curp.name} to #{newvalue}"
      settings = "#{seqn}:#{newvalue.to_s}"
      if hosemas then
        verbose_report "sending: reqindparmod with: #{curp.name}, #{settings}"
        $client.request_indicator_parameters_modification(curp.name, settings)
        # This call also triggers the server issue:
        $client.request_indicator_parameters(curp.name)
      else
        verbose_report "sending: reqindparmod with: #{indname}, #{settings}"
        $client.request_indicator_parameters_modification(indname, settings)
      end
      $client.request_indicator_parameters(indname)
      newparams = $client.indicator_parameters
      oldp = parameters[seqn-1]; newp = newparams[seqn-1]
      verbose_report "OLDP: #{oldp.name}, #{oldp.value}"
      verbose_report "NEWP: #{newp.name}, #{newp.value}"
      assert newparams.count > 0, "#{indname} NOT have 0 params"
      assert oldp.name == newp.name,
        "names the same (#{oldp.name}/#{newp.name})"
      assert oldp.value != newp.value, "values (should) NOT (be) the same: " +
        "#{oldp.value} vs #{newp.value}"
      assert newp.value == newvalue.to_s, "new value correct (\n" +
        "It's supposed to be #{newvalue.to_s}, but it's #{newp.value}"
    end
  end

  # Test that the MAS server responds sanely to an invalid indicator name.
  def test_server_response_to_invalid_indname
    indname = "Slope of MACD Signal Line Trend"
    $client.request_indicator_parameters(indname)
    parameters = $client.indicator_parameters
    assert parameters.count > 0, "#{indname} NOT have 0 params"
    pname = parameters[0].name
    settings = "1:22"
    verbose_report "sending: req-param-mod bad name: #{pname}"
    $client.request_indicator_parameters_modification(pname, settings)
    assert $client.server_error, "expected server error status"
    assert ! $client.last_error_msg.nil?, "msg: #{$client.last_error_msg}"
    verbose_report "server said: #{$client.last_error_msg}"
    verbose_report "sending: req-ind-param bad name: #{pname}"
    $client.request_indicator_parameters(pname)
    assert $client.server_error, "expected server error status"
    assert ! $client.last_error_msg.nil?, "msg: #{$client.last_error_msg}"
    verbose_report "server said: #{$client.last_error_msg}"
  end

  def test_indicator_parameters_modification_with_verification
    switch_to_inidicators
    failures = []
    inames = [
      'MACD Difference',
      'MACD Signal Line (EMA of MACD Difference)',
      "Slope of MACD Signal Line",
      "Simple Moving Average",
      "Exponential Moving Average",
    ]
    inames.each do |ind_name|
      settings = client_request_for(ind_name)
      $client.request_indicator_parameters_modification(ind_name, settings)
      $client.request_indicator_parameters(ind_name)
      prefix = 1
      $client.indicator_parameters.each do |p|
        verbose_report "#{p.value} [#{p.type_desc}, #{p.name}]"
        expected_value = value_for(ind_name, "#{prefix.to_s}:#{p.name}")
        if expected_value != p.value then
          failures << "expected: " + "#{expected_value.ljust(2)}, " +
            "got: #{p.value.ljust(3)}" + " [#{ind_name}/#{p.name}]"
        end
        prefix += 1
      end
    end
    assert failures.empty?, "GROUP 1 - #{failures.count} failures:\n" +
      failures.join("\n")
    failures = []
    ind_name = inames[1]
    tgtpname = "3:n-value - MACD Signal Line (EMA of MACD Difference)"
    settings = client_request_for(ind_name, {tgtpname => true})
    $client.request_indicator_parameters_modification(ind_name, settings)
    $client.request_indicator_parameters(ind_name)
    prefix = 1
    $client.indicator_parameters.each do |p|
      verbose_report "#{p.value} [#{p.type_desc}, #{p.name}]"
      expected_value = value_for(ind_name, "#{prefix.to_s}:#{p.name}")
      if expected_value != p.value then
        failures << "expected: " + "#{expected_value.ljust(2)}, " +
          "got: #{p.value.ljust(3)}" + " [#{ind_name}/#{p.name}]"
      end
      prefix += 1
    end
    assert failures.empty?, "GROUP 2 - #{failures.count} failures:\n" +
      failures.join("\n")
    failures = []
    ind_name = inames[1]
    tgtpname = "3:n-value - MACD Signal Line (EMA of MACD Difference)"
    change_param_value(ind_name, tgtpname, 42)
    settings = client_request_for(ind_name, {tgtpname => true})
    $client.request_indicator_parameters_modification(ind_name, settings)
    $client.request_indicator_parameters(ind_name)
    prefix = 1
    $client.indicator_parameters.each do |p|
      verbose_report "#{p.value} [#{p.type_desc}, #{p.name}]"
      expected_value = value_for(ind_name, "#{prefix.to_s}:#{p.name}")
      if expected_value != p.value then
          failures << "expected: " + "#{expected_value.ljust(2)}, " +
            "got: #{p.value.ljust(3)}" + " [#{ind_name}/#{p.name}]"
      end
      prefix += 1
    end
    assert failures.empty?, "GROUP 3 - #{failures.count} failures:\n" +
      failures.join("\n")
  end

  def test_indicator_parameters
    symbol = 'ibm'
    $client.request_indicators(symbol, MasClient::DAILY)
    indicators = $client.indicators
    assert indicators.length > 0
    indicators.each do |i|
      $client.request_indicator_parameters(i)
      $client.indicator_parameters.each do |p|
        verbose_report "#{p.value} [#{p.type_desc}, #{p.name}]"
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
    $client1 = InitialSetup::new_client
    $client2 = InitialSetup::new_client
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
    $client1.logout
    $client2.logout
  end

  def test_analyzer_parameters
    symbol = 'ibm'
    $client.request_analyzers(symbol, MasClient::DAILY)
    analyzers = $client.analyzers
    assert analyzers.length > 0
    analyzers.each do |a|
      $client.request_analysis_parameters(a.name, DAILY_PERIOD_TYPE)
      $client.analysis_parameters.each do |p|
        verbose_report "#{p.value} [#{p.type_desc}, #{p.name}]"
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
      $client.request_analysis_parameters_modification(ana_name,
          DAILY_PERIOD_TYPE, "2:3,3:19")
      if $client.server_error then
        msg = "#{$client.last_error_msg}"
        verbose_report msg
        assert false, msg
      else
        do_analysis(symbol, [period_type], selected, start_date, end_date)
        data1 = $client.analysis_data
        count1 = data1.count

        $client.request_analysis_parameters_modification(ana_name,
            DAILY_PERIOD_TYPE, "2:13,3:26")
        do_analysis(symbol, [period_type], selected, start_date, end_date)
        data2 = $client.analysis_data
        count2 = data2.count
        assert data1 != data2, 'result of different params not equal'
        assert data1[0] != data2[0], 'first event not equal [1 vs 2]'
        assert count1 != count2, 'counts not equal [1 vs 2]'

        $client.request_analysis_parameters_modification(ana_name,
            DAILY_PERIOD_TYPE, "2:39,3:97")
        do_analysis(symbol, [period_type], selected, start_date, end_date)
        data3 = $client.analysis_data
        count3 = data3.count
        assert data1 != data3, 'result of different params not equal[2]'
        assert data1[0] != data3[0], 'first event not equal [1 vs 3]'
        assert count1 != count3, 'counts not equal [1 vs 3]'
      end
    end
  end

  # (Note: This test is unstable. See note at top [above class ParameterTest]).
  def test_analyzer_parameters_modification2
    symbol = 'ibm'
    # (Log 2 clients in, set different parameter-settings for the same
    # analyzer, request param settings and analyzer data and verify that
    # the 2 clients don't step on each other - they each use the correct
    # parameter settings.)
    $client1 = InitialSetup::new_client
    $client2 = InitialSetup::new_client
    $client1.request_analyzers(symbol, MasClient::DAILY)
    $client2.request_analyzers(symbol, MasClient::DAILY)
    analyzers1 = $client1.analyzers
    analyzers2 = $client2.analyzers
    assert analyzers1.count == analyzers2.count, 'analyzer lists counts equal'
    for i in 0..analyzers1.count-1 do
      assert analyzers1[i].name == analyzers2[i].name,
        'analyzer lists: names equal'
      assert analyzers1[i].event_id == analyzers2[i].event_id,
        'analyzer lists: ids equal'
    end

    ana_name = 'Slope of MACD Signal Line Cross Above 0 (Buy)'
    slope_macd_sl0_idx = 5
    start_date = DateTime.new(2012, 01, 01)
    end_date = DateTime.new(2038, 07, 01)
    # Note the "- 1", due to the MAS interface using indexes starting at 1:
    selected = [analyzers2[slope_macd_sl0_idx - 1]]
    assert selected[0].name == ana_name, 'correct analyzer'

    ['daily'].each do |period_type|
      $client1.request_analysis_parameters_modification(ana_name,
          DAILY_PERIOD_TYPE, "2:5,3:13")
      do_analysis(symbol, [period_type], selected, start_date, end_date,
                  $client1)
      $client2.request_analysis_parameters_modification(ana_name,
          DAILY_PERIOD_TYPE, "2:27,3:43")
      do_analysis(symbol, [period_type], selected, start_date, end_date,
                  $client2)
      cl2data = $client2.analysis_data
      cl1data = $client1.analysis_data
      assert cl1data != cl2data, 'cl1/cl2 data should differ'
      assert cl1data[0] != cl2data[0], 'cl1[0]/cl2[0] data should differ'
      assert cl1data.count != cl2data.count, 'cl1/cl2 counts should differ' +
        "(#{cl1data.count} vs #{cl2data.count})"
      # Test that client2's parameters don't step on client1's parameters.
      do_analysis(symbol, [period_type], selected, start_date, end_date,
                  $client1)
      cl1data_II = $client1.analysis_data
      do_analysis(symbol, [period_type], selected, start_date, end_date,
                  $client2)
      cl2data_II = $client2.analysis_data
      assert cl1data_II != cl2data_II, 'cl1-later vs cl2-later differ'
      assert cl2data_II[0].datetime != cl1data_II[0].datetime,
        'first event date not equal'
      cl2data_II[-1]
      assert cl2data_II[-1].datetime != cl1data_II[-1].datetime,
        "last event date not equal " +
        "[#{cl2data_II[-1].datetime} vs #{cl1data_II[-1].datetime}]"
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
        assert cl1data[j].analyzer.event_id ==
          cl1data_II[j].analyzer.event_id,
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
        assert cl2data[j].analyzer.event_id ==
          cl2data_II[j].analyzer.event_id,
          'same ana-ids 2'
      end
    end
    $client1.logout
    $client2.logout
  end

  def test_analysis_daily_vs_weekly
    symbol = 'ibm'
    cl1ptype = DAILY_PERIOD_TYPE
    cl2ptype = WEEKLY_PERIOD_TYPE
    # (Log 2 clients in - use daily period-type for client1 and weekly for
    # client 2; with the same analyzer, use the same parameter settings for
    # both and verify that the results for client 1 are different from those
    # of client 2.
    $client1 = InitialSetup::new_client
    $client2 = InitialSetup::new_client
    param_settings = "2:5,3:13"
    $client1.request_analyzers(symbol, MasClient::DAILY)
    $client2.request_analyzers(symbol, MasClient::DAILY)
    analyzers1 = $client1.analyzers
    analyzers2 = $client2.analyzers
    assert analyzers1.count == analyzers2.count, 'analyzer lists counts equal'
    ana_name = 'Slope of MACD Signal Line Cross Above 0 (Buy)'
    slope_macd_sl0_idx = 4
    start_date = DateTime.new(2010, 01, 01)
    end_date = DateTime.new(2015, 07, 01)
    selected = [analyzers2[slope_macd_sl0_idx]]
    assert selected[0].name == ana_name, 'correct analyzer'
    $client1.request_analysis_parameters_modification(ana_name, cl1ptype,
                                                      param_settings)
    do_analysis(symbol, [cl1ptype], selected, start_date, end_date, $client1)
    # (Use the same param_settings for $client1 and $client2.)
    $client2.request_analysis_parameters_modification(ana_name, cl2ptype,
                                                      param_settings)
    do_analysis(symbol, [cl2ptype], selected, start_date, end_date, $client2)
    cl2data = $client2.analysis_data
    cl1data = $client1.analysis_data
    assert cl1data != cl2data, 'cl1/cl2 data should differ'
    assert cl1data[0] != cl2data[0], 'cl1/cl2 1st elements should differ'
    assert cl1data.count > cl2data.count, 'cl1-count > cl2-count expected' +
      " (#{cl1data.count} vs #{cl2data.count})"
    $client1.logout
    $client2.logout
  end

  def test_analysis_weekly_vs_monthly
    symbol = 'ibm'
    cl1ptype = WEEKLY_PERIOD_TYPE
    cl2ptype = MONTHLY_PERIOD_TYPE
    # (Log 2 clients in - use daily period-type for client1 and weekly for
    # client 2; with the same analyzer, use the same parameter settings for
    # both and verify that the results for client 1 are different from those
    # of client 2.
    $client1 = InitialSetup::new_client
    $client2 = InitialSetup::new_client
    param_settings = "2:5,3:13"
    $client1.request_analyzers(symbol, MasClient::DAILY)
    $client2.request_analyzers(symbol, MasClient::DAILY)
    analyzers1 = $client1.analyzers
    analyzers2 = $client2.analyzers
    assert analyzers1.count == analyzers2.count, 'analyzer lists counts equal'
    ana_name = 'Slope of MACD Signal Line Cross Above 0 (Buy)'
    slope_macd_sl0_idx = 4
    start_date = DateTime.new(2010, 01, 01)
    end_date = DateTime.new(2015, 07, 01)
    selected = [analyzers2[slope_macd_sl0_idx]]
    assert selected[0].name == ana_name, 'correct analyzer'
    $client1.request_analysis_parameters_modification(ana_name, cl1ptype,
                                                      param_settings)
    do_analysis(symbol, [cl1ptype], selected, start_date, end_date, $client1)
    # (Use the same param_settings for $client1 and $client2.)
    $client2.request_analysis_parameters_modification(ana_name, cl2ptype,
                                                      param_settings)
    do_analysis(symbol, [cl2ptype], selected, start_date, end_date, $client2)
    cl2data = $client2.analysis_data
    cl1data = $client1.analysis_data
    assert cl1data != cl2data, 'cl1/cl2 data should differ'
    assert cl1data[0] != cl2data[0], 'cl1/cl2 1st elements should differ'
    assert cl1data.count > cl2data.count, 'cl1-count > cl2-count expected' +
      " (#{cl1data.count} vs #{cl2data.count})"
    $client1.logout
    $client2.logout
  end

  # Run analysis with 2 different period-types at the same time
  def test_analysis_daily_and_weekly
    symbol = 'ibm'
    ptype1 = DAILY_PERIOD_TYPE
    ptype2 = WEEKLY_PERIOD_TYPE
    client = InitialSetup::new_client
    param_settings1 = "2:5,3:13,1:7"
    param_settings2 = "2:9,3:17,1:6"
    client.request_analyzers(symbol)
    analyzers = client.analyzers
    assert analyzers.count > 0, 'some analyzers'
    ana_name = 'Slope of MACD Signal Line Cross Above 0 (Buy)'
    slope_macd_sl0_idx = 4
    startdt = DateTime.new(2010, 01, 01)
    enddt = DateTime.new(2015, 07, 01)
    selected = [analyzers[slope_macd_sl0_idx], analyzers[slope_macd_sl0_idx]]
    assert selected[0].name == ana_name, 'correct analyzer'
    client.request_analysis_parameters_modification(ana_name, ptype1,
                                                    param_settings1)
    client.request_analysis_parameters_modification(ana_name, ptype2,
                                                    param_settings2)
    client.request_analysis(selected, [ptype1, ptype2], symbol, startdt, enddt)
    data = client.analysis_data
    assert data.count > 0, "data.count > 0 (#{data.count})"
    client.logout
  end

  def test_macd_xover_analysis
    failures = []
    ptype = DAILY_PERIOD_TYPE
    $macd_xvr_client = InitialSetup::new_client
    oracle = MACD_CrossoverBuyOracle.new
    symbol = oracle.symbol
    expected_count = oracle.expected_count
    param_settings = oracle.parameter_settings
    $macd_xvr_client.request_analyzers(symbol)
    analyzers = $macd_xvr_client.analyzers
    assert analyzers.count > 2, 'analyzer count'
    start_date = oracle.start_date
    end_date = oracle.end_date
    selected = [oracle.selected_analyzer(analyzers)]
    assert selected.count > 0, 'analyzer found'
    $macd_xvr_client.request_analysis_parameters_modification(
      selected[0].name, ptype, param_settings)
    if $macd_xvr_client.server_error then
      msg = "#{$macd_xvr_client.last_error_msg}"
      verbose_report msg
      failures << msg
    else
      do_analysis(symbol, [ptype], selected, start_date, end_date,
                  $macd_xvr_client)
    end
    assert failures.empty?, "parameter mod failures:\n" + failures.join("\n")
    data = $macd_xvr_client.analysis_data
    assert data.count == expected_count,
      "data-count (#{data.count}) should be #{expected_count}"
    assert oracle.results_correct(data), "data was incorrect"
    param_settings = "1:12,2:26,3:12,4:26,5:6"
    $macd_xvr_client.request_analysis_parameters_modification(
      selected[0].name, ptype, param_settings)
    do_analysis(symbol, [ptype], selected, start_date, end_date,
                $macd_xvr_client)
    data = $macd_xvr_client.analysis_data
    # (With different parameter settings, the results should be different:)
    assert ! oracle.results_correct(data), "data was unexpectedly correct"
    $macd_xvr_client.logout
  end

#!!!!to-do: Create a test to run macd-xover daily twice, the 2nd time
#!!!! mixed with some other spec; use the oracle to make sure the
#!!!! macd-xover results are correct (not "polluted" by the other spec).
  def test_macd_xover_analysis_daily_and_weekly
    failures = []
    ptype1 = DAILY_PERIOD_TYPE
    ptype2 = WEEKLY_PERIOD_TYPE
    client = InitialSetup::new_client
    oracle = MACD_CrossoverBuyOracle.new
    symbol = oracle.symbol
    expected_count = oracle.expected_count
    # (expected daily count augmented by a low estimate of weekly count:)
    augmented_count = expected_count + 5
    param_settings = oracle.parameter_settings
    client.request_analyzers(symbol)
    analyzers = client.analyzers
    start_date = oracle.start_date
    end_date = oracle.end_date
    our_analyzer = oracle.selected_analyzer(analyzers)
    selected = [our_analyzer, our_analyzer]
    client.request_analysis_parameters_modification(
      selected[0].name, ptype1, param_settings)
    client.request_analysis_parameters_modification(
      selected[1].name, ptype2, param_settings)
    if client.server_error then
      msg = "#{client.last_error_msg}"
      verbose_report msg
      failures << msg
    else
      client.request_analysis(selected, [ptype1, ptype2], symbol,
                              start_date, end_date)
    end
    assert failures.empty?, "parameter mod failures:\n" + failures.join("\n")
    data = client.analysis_data
    assert data.count > augmented_count,
      "data-count (#{data.count}) should be > #{augmented_count}"
    assert oracle.results_fuzzily_correct(data), "data was incorrect"
    client.logout
  end

  # Test "MACD Crossover ..." buy AND sell together: ~(2*buy) signals
  def test_macd_xover_buy_and_sell_analysis
    failures = []
    ptype = DAILY_PERIOD_TYPE
    ptypes = [ptype, ptype]
    $macd_xvr_client = InitialSetup::new_client
    oracle = MACD_CrossoverBuyOracle.new
    symbol = oracle.symbol
    single_ana_expected_count = oracle.expected_count
    approx_count = single_ana_expected_count * 2
    param_settings = "1:5,2:13,3:5,4:13,5:6"
    $macd_xvr_client.request_analyzers(symbol)
    analyzers = $macd_xvr_client.analyzers
    assert analyzers.count > 2, 'analyzer count'
    start_date = oracle.start_date
    end_date = oracle.end_date
    selected = oracle.selected_analyzers(analyzers,
                                         'MACD\s*Crossover\s*.?(buy|sell)')
    assert selected.count > 0, 'analyzer found'
    selected.each do |a|
      $macd_xvr_client.request_analysis_parameters_modification(a.name, ptype,
                                                                param_settings)
    end
    if $macd_xvr_client.server_error then
      msg = "#{$macd_xvr_client.last_error_msg}"
      verbose_report msg
      failures << msg
    else
      do_analysis(symbol, ptypes, selected, start_date, end_date,
                  $macd_xvr_client)
    end
    assert failures.empty?, "parameter mod failures:\n" + failures.join("\n")
    data = $macd_xvr_client.analysis_data
    assert data.count > single_ana_expected_count,
      "data-count (#{data.count}) should be > #{single_ana_expected_count}"
    assert data.count > approx_count - 2 && data.count < approx_count + 2,
      "data-count (#{data.count}) should be around #{approx_count}"
    assert ! oracle.results_correct(data), 'data should NOT be "correct"'
    param_settings = "1:12,2:26,3:12,4:26,5:6"
    selected.each do |a|
      $macd_xvr_client.request_analysis_parameters_modification(a.name, ptype,
                                                                param_settings)
    end
    do_analysis(symbol, ptypes, selected, start_date, end_date,
                $macd_xvr_client)
    data = $macd_xvr_client.analysis_data
    # (With different parameter settings, the results should be different:)
    assert ! oracle.results_correct(data), "data was unexpectedly correct"
    assert data.count < approx_count,
      "data-count (#{data.count}) should be < #{approx_count}"
    $macd_xvr_client.logout
  end

#!!!!TO-DO: Make similar test that uses "Volume > Yesterday's Volume EMA"
#!!!! and 4 or 5 or so symbols (See ../../doc/bugreports.)
  def test_macd_xover_analysis_with_2_symbols
    failures = []
    ptype = DAILY_PERIOD_TYPE
    $macd_xvr_client = InitialSetup::new_client
    oracle = MACD_CrossoverBuyOracle.new
    symbol1 = oracle.symbol
    symbol2 = 'aapl'
    expected_s1_count = oracle.expected_count
    param_settings = "1:5,2:13,3:5,4:13,5:6"
    $macd_xvr_client.request_analyzers(symbol1)
    analyzers = $macd_xvr_client.analyzers
    start_date = oracle.start_date
    end_date = oracle.end_date
    selected = [oracle.selected_analyzer(analyzers)]
    slope_macd_sl0_idx = 4
    # Use a different analyzer to see if there's any "interference".
    selected2 = [analyzers[slope_macd_sl0_idx]]
    $macd_xvr_client.request_analysis_parameters_modification(
      selected[0].name, ptype, param_settings)
    if $macd_xvr_client.server_error then
      msg = "#{$macd_xvr_client.last_error_msg}"
      verbose_report msg
      failures << msg
    else
      do_analysis(symbol1, [ptype], selected, start_date, end_date,
                  $macd_xvr_client)
    end
    assert failures.empty?, "parameter mod failures:\n" + failures.join("\n")
    data = $macd_xvr_client.analysis_data
    assert data.count == expected_s1_count,
      "data-count (#{data.count}) should be #{expected_s1_count}"
    assert oracle.results_correct(data), "data was incorrect"
    do_analysis(symbol2, [ptype], selected2, start_date, end_date,
                  $macd_xvr_client)
    data = $macd_xvr_client.analysis_data
    assert ! oracle.results_correct(data),
      "data for #{symbol1} unexpectedly matched that of #{symbol2}" +
      "(oracle count, symbol2-count: #{expected_s1_count}, #{data.count}"
    # Do symbol1 again:
    do_analysis(symbol1, [ptype], selected, start_date, end_date,
                  $macd_xvr_client)
    data = $macd_xvr_client.analysis_data
    assert data.count == expected_s1_count,
      "data-count (#{data.count}) should be #{expected_s1_count}"
    assert oracle.results_correct(data), "data was incorrect"
    $macd_xvr_client.logout
  end

  def fix_this_test_analyzer_parameters_modification3
    switch_to_analyzers
    failures = []
    anames = [
      "MACD Crossover (Buy)",
      "MACD Crossover (Sell)",
      "Stochastic %D Crossover (Buy)",
    ]
    anames.each do |ana_name|
      settings = client_request_for(ana_name)
      $client.request_analysis_parameters_modification(ana_name, settings)
      $client.request_analysis_parameters(ana_name)
      prefix = 1
      $client.analysis_parameters.each do |p|
        verbose_report "#{p.value} [#{p.type_desc}, #{p.name}]"
        expected_value = value_for(ana_name, "#{prefix.to_s}:#{p.name}")
        if expected_value != p.value then
          failures << "[#{ana_name}/#{p.name}] expected: " +
            "#{expected_value}, got: #{p.value}"
        end
        prefix += 1
      end
    end
    assert failures.empty?, "GROUP 1 - #{failures.count} failures:\n" +
      failures.join("\n")
    failures = []
    ana_name = anames[1]
    tgtpname = "5:n-value - MACD Signal Line (EMA of MACD Difference)"
    settings = client_request_for(ana_name, {tgtpname => true})
    $client.request_analysis_parameters_modification(ana_name, settings)
    $client.request_analysis_parameters(ana_name)
    prefix = 1
    $client.analysis_parameters.each do |p|
      verbose_report "#{p.value} [#{p.type_desc}, #{p.name}]"
      expected_value = value_for(ana_name, "#{prefix.to_s}:#{p.name}")
      if expected_value != p.value then
        failures << "[#{ana_name}/#{p.name}] expected: " +
        "#{expected_value}, got: #{p.value}"
      end
      prefix += 1
    end
    assert failures.empty?, "GROUP 2 - #{failures.count} failures:\n" +
      failures.join("\n")
    failures = []
    ana_name = anames[1]
    tgtpname = "5:n-value - MACD Signal Line (EMA of MACD Difference)"
    change_param_value(ana_name, tgtpname, 42)
    settings = client_request_for(ana_name, {tgtpname => true})
    $client.request_analysis_parameters_modification(ana_name, settings)
    $client.request_analysis_parameters(ana_name)
    prefix = 1
    $client.analysis_parameters.each do |p|
      verbose_report "#{p.value} [#{p.type_desc}, #{p.name}]"
      expected_value = value_for(ana_name, "#{prefix.to_s}:#{p.name}")
      if expected_value != p.value then
        failures << "[#{ana_name}/#{p.name}] expected: " +
        "#{expected_value}, got: #{p.value}"
      end
      prefix += 1
    end
    assert failures.empty?, "GROUP 3 - #{failures.count} failures:\n" +
      failures.join("\n")
  end

end

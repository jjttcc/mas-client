require 'ruby_contracts'
require 'minitest/autorun'
require_relative './test_setup'


class AnalyzerTest < MiniTest::Test
  include TestSetup

  def test_check_all_analyzers
    $client.request_analyzers("ibm", MasClient::DAILY)
    analyzers = $client.analyzers
    assert analyzers.length > 0
    analyzers.each do |a|
      assert ! a.name.empty?, "Emtpy analyzer (#{a})"
    end
  end

  def test_analyzer_list
    hourly, daily, monthly =
      MasClient::HOURLY, MasClient::DAILY, MasClient::MONTHLY
    [hourly, daily, monthly].each do |pt|
      begin
        $client.request_analyzers("ibm", pt)
        if $client.communication_failed then
          $log.warn("request_analyzers failed for #{pt} " +
                    "(\n#{$client.last_exception})")
          assert false, 'request (to MAS server) of analyzers failed'
        else
          analyzers = $client.analyzers
          assert analyzers.class == [].class, "analyzers is an array"
          if $client.server_error then
            if pt == hourly then
              puts "ERROR for hourly data (expected):\n#{$client.last_error_msg}"
            else
              assert false, "unexpected server error for #{pt} data"
            end
          else
            assert analyzers.count > 1, 'At least two analyzers'
            verbose_report "<<<<<There were #{analyzers.length} analyzers>>>>>"
            analyzers.each do |a|
              assert a.respond_to?(:event_id) && a.respond_to?(:name),
                '"analyzer" object must respond to "event_id" and "name"'
              if InitialSetup::verbose then puts a.inspect end
            end
          end
        end
      rescue => e
        puts "e: #{e}"
      end
    end
  end

  def test_analysis
    symbol = 'ibm'
    $client.request_analyzers(symbol, MasClient::DAILY)
    selected_analyzers = $client.analyzers[1..6]
    period_types = selected_analyzers.map do |a|
      DAILY_PERIOD_TYPE
    end
    now = DateTime.now
    enddt = Date.new(now.year, now.month, now.day)
    startdt = enddt - 3650
    spec = PerTypeSpec.new(period_type: MasClient::DAILY,
                           start_date: enddt - 960, end_date: enddt)
    $client.request_analysis(selected_analyzers, period_types, symbol,
                             spec.start_date)
    events = $client.analysis_data
    if events.length > 1
      verbose_report "\n#{events.length} events:"
      events.each do |e|
        if InitialSetup::verbose
          puts "<<#{e}>>"
        end
        assert_kind_of TradableEventInterface, e
        assert_kind_of String, e.event_type
        assert e.datetime != nil, 'valid datetime'
      end
    end
    $client.request_analysis(selected_analyzers, period_types, symbol,
                             startdt, enddt)
    events = $client.analysis_data
    if events.length > 1
      verbose_report "\nfirst and last (of #{events.length}) events:"
      [events[0], events[-1]].each do |e|
        if InitialSetup::verbose
          puts "<<#{e}>>"
        end
        assert_kind_of TradableEventInterface, e
        assert_kind_of String, e.event_type
        assert e.datetime != nil, 'valid datetime'
      end
    end
  end

end

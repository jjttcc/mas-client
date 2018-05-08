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
    [MasClient::HOURLY, MasClient::DAILY, MasClient::MONTHLY].each do |pt|
      begin
        $client.request_analyzers("ibm", pt)
        if $client.communication_failed then
          $log.warn("request_analyzers failed for #{pt} " +
                    "(\n#{$client.last_exception})")
        else
          analyzers = $client.analyzers
          assert analyzers.class == [].class, "analyzers is an array"
          if analyzers.length == 0
            puts "<<<<<No analyzers found>>>>>"
          else
            verbose_report "<<<<<There were #{analyzers.length} analyzers>>>>>"
            analyzers.each do |a|
              assert_kind_of TradableAnalyzer, a
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
    now = DateTime.now
    enddt = Date.new(now.year, now.month, now.day)
    startdt = enddt - 3650
    spec = PerTypeSpec.new(period_type: MasClient::DAILY,
                           start_date: enddt - 960, end_date: enddt)
    $client.set_period_type_spec(spec)
    $client.request_analysis(selected_analyzers, symbol, spec.start_date)
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
    $client.request_analysis(selected_analyzers, symbol, startdt, enddt)
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

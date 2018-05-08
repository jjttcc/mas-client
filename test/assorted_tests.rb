require 'ruby_contracts'
require 'minitest/autorun'
require_relative './test_setup'


class DataTest < MiniTest::Test
  include TestSetup

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

  def test_period_types
    $client.request_period_types("ibm")
    ptypes = $client.period_types
    assert ptypes.length > 0
    assert (ptypes.include? "daily"), "Missing symbol"
    assert (ptypes.include? "weekly"), "Missing symbol"
    assert (ptypes.include? "monthly"), "Missing symbol"
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

end

require 'minitest/autorun'
require_relative '../mas_client'

class TestMasClient < MiniTest::Unit::TestCase
  def setup
    port = ENV['MASPORT'] || 5001
    @client = MasClient.new(port)
    assert_equal @client.port, port
  end

  def test_key
    assert_match /^\d+/, @client.session_key, "good session key"
  end

  def test_symbols
    @client.request_symbols
    symbols = @client.symbols
    assert symbols.length > 0
    # (Assumption: test symbol list always includes ibm.)
    assert (symbols.include? "ibm"), "Missing symbol"
    assert (symbols.include? "jnj"), "Missing symbol"
  end

  def test_that_will_be_skipped
    skip "test this later"
  end
end

# (Copied from:
# http://stackoverflow.com/questions/1197224/source-shell-script-into-environment-within-a-ruby-script)

# Read in the bash environment, after an optional command.
#   Returns Array of key/value pairs.
def bash_env(cmd=nil)
  env = `#{cmd + ';' if cmd} printenv`
  env.split(/\n/).map {|l| l.split(/=/)}
end

# Source a given file, and compare environment before and after.
#   Returns Hash of any keys that have changed.
def bash_source(file)
  Hash[ bash_env(". #{File.realpath file}") - bash_env() ]
end

# Find variables changed as a result of sourcing the given file, 
#   and update in ENV.
def source_env_from(file)
  bash_source(file).each {|k,v| ENV[k] = v }
end

require 'ruby_contracts'
require 'minitest/autorun'
$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/../utility")
require 'global_log'
require_relative '../mas_client/mas_client'
require_relative '../mas_client/mas_client_optimized'
require_relative '../mas_client/mas_client_nonblocking'
require_relative './hide_tradable_analyzer.rb'
require_relative './test_tradable_event'
require_relative '../mas_client/function_parameter'
require_relative '../mas_client/object_spec'
require_relative './parameter_test_tools'


module TestSetup
  class TradableObjectFactory
    include Contracts::DSL, TimePeriodTypeConstants

    # A new TradableAnalyzer with the specified name and id
    def new_analyzer(name:, id:, period_type:)
      TradableAnalyzer.new(name, id, is_intraday(period_type))
    end

    def new_event(date:, time:, id:, type_id:, analyzers:)
      datetime = DateTime.new(date[0..3].to_i, date[4..5].to_i, date[6..7].to_i,
                              time[0..1].to_i, time[2..3].to_i, time[4..5].to_i)
      event_type_id = type_id
      selected_ans = analyzers.select {|a| a.event_id == id }
      if selected_ans.length == 0
        raise "new_event: id arg, #{id} " +
        "does not identify any known analyzer."
      else
        analyzer = selected_ans[0]
      end
      TestTradableEvent.new(datetime, event_type_id, analyzer)
    end

    def new_parameter(name:, type_desc:, value:)
      FunctionParameter.new(name, type_desc, value)
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

      def settings
        HASHTABLE
      end

      HASHTABLE = {
        host: 'localhost', port: ENV['MASPORT'],
        factory: TradableObjectFactory.new, close_after_w: false,
        timeout: 4,
      }
    end

    def self.new_client
      if ENV['OPTIMIZE']
        if InitialSetup::verbose then puts "Using MasClientNonblocking" end
        result = MasClientNonblocking.new(InitialSetup::MasClientArgs.new)
      else
        if InitialSetup::verbose then puts "Using MasClient" end
        result = MasClient.new(host: 'localhost', port: port,
                               factory: TradableObjectFactory.new, timeout: 4)
      end
      result
    end

    def initialize
      # Source the .env file to get the $MASPORT env. var.
      testpath = File::dirname($0)
      source_env_from(testpath + '/.env')
      if ! ENV["MC_NO_SERVER_START"] then
        mas_script = testpath + '/startmas'
        if ! system mas_script; then exit 222 end
      else
        $stderr.puts "Skipping auto-starting mas server"
      end
      $client = self.class.new_client
      if not $client.logged_in
        puts "Login of client failed - aborting test"
        exit 95
      end
    end

    def self.verbose
      ENV['VERBOSE']
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

  sc = InitialSetup.new
  $fin_set = false
  SLEEP = true

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
  end

  def verbose_report(msg)
    if msg && InitialSetup::verbose && ! msg.empty? then
      $stderr.puts msg
    end
  end

end

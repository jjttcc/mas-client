require 'ruby_contracts'
require 'sys/proctable'
require 'mas_client'
require 'mas_client_optimized'
require 'timeout'

class MasMonitor
  include Contracts::DSL, Sys

  public ###  Access

  @@service_name = 'monitor'

  attr_accessor :host, :main_port, :sleep_seconds, :startup_margin,
    :kill_margin, :cmd_name_pattern, :server_start_cmd

  public ###  Status report

  post :boolean do |result| result == true || result == false end
  def server_is_healthy
    result = false
    client = nil
    if @verbose then puts "[sih]" end
    begin
      timeout_status = Timeout::timeout(5) {
        client = new_client
        result = client.logged_in
        client.logout
        true
      }
    rescue => e
      result = false
      if @verbose then puts "timeout_status: #{timeout_status.inspect}" end
    end
    if @verbose
      puts "server is" + ((result)? '': ' NOT') + " healthy"
    end
    result
  end

  public ###  Basic operations

  def run_forever
    loop do
      if not server_is_healthy
        restart_server
        if not server_is_healthy
          increment_margins
          next
        end
      end
      if @verbose then puts "run_f - sleep #{sleep_seconds}" end
      sleep sleep_seconds
    end
  rescue Interrupt => e
    puts "#{@@service_name} Terminated"
  end

  private ###  Initialization

  @ping_limit = 4

  type in: Object
  pre :settings_valid do |s| s.respond_to?(:main_port) &&
    s.respond_to?(:host) && s.respond_to?(:cmd_name_pattern) &&
    s.respond_to?(:server_start_cmd)
  end
  def initialize(settings: settings)
    @verbose = ENV['MM_VERBOSE'] != nil
    @main_port = settings.main_port
    @host = settings.host
    @sleep_seconds = 10
    @startup_margin = 6
    @kill_margin = 25
    @cmd_name_pattern = settings.cmd_name_pattern
    @server_start_cmd = settings.server_start_cmd
  end

  private

  def new_client
    if @verbose
      puts "'ping'ing client at port #{main_port}"
    end
    result = MasClientOptimized.new(host: host, port: main_port,
      factory: TradableObjectFactory.new)
  end

  # Restart the target server - kill it first if it's already running.
  def restart_server
    ProcTable.ps do |proc|
      if proc.comm =~ /#{cmd_name_pattern}/
        kill_process(proc)
        break
      end
    end
    start_server
  end

  def kill_process(proc)
    if @verbose then puts "killing #{proc.pid}" end
    begin
      Process.kill(:TERM, proc.pid)
      sleep 0.75
      Process.kill(:KILL, proc.pid) # Ensure it's really dead.
    rescue
    end
    if @verbose then puts "kp - sleep #{kill_margin}" end
    sleep kill_margin
  end

  def start_server
    pid = fork
    if pid.nil? then
      # (child)
      if @verbose
        puts "starting server with command: '#{server_start_cmd}'"
      end
      Process.daemon(true, true)
      exec server_start_cmd
    else
    end
    if @verbose then puts "ss - sleep #{startup_margin}" end
    sleep startup_margin
  end

  def increment_margins
    @kill_margin += 5
    @startup_margin += 2
  end

end

class TradableObjectFactory

  def new_analyzer(name: name, id: id, period_type: period_type)
    # dummy
  end

  def new_event(date: date, time: time, id: id, type_id: type_id,
                analyzers: analyzers)
    # dummy
  end

  def new_parameter(name: name, type_desc: type_desc, value: value)
    # dummy
  end

end

require 'ruby_contracts'
require 'client_connection'
require 'ma_communication_protocol'
require 'timer'

# Socket connection facilities for Market Analysis
# command-line clients.
class Connection < ClientConnection
  public :close, :send_request

  include Contracts::DSL, MACommunicationProtocol

  private

  ##### Initialization

  # Setup initial state and begin the conversation with
  # the server.
  pre  :host_port do |host, port| ! (host.nil? || port.nil?) end
  post :response_set_on_success do
    implies(last_communication_succeeded, server_response != nil) end
  def initialize(host, port)
    make_connected(host, port)
    if last_communication_succeeded then
      send_message(CONSOLE_FLAG)
    end
  end

  public

  ##### Status report

  attr_reader :termination_requested

  # Is timing of requests/responses on?
  attr_reader :timing

  ##### Status setting

  # Debug
  def do_debug
=begin
#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!TO-DO - fix:
    print ("rec. buf size: " + socket.receive_buf_size.to_s + "\n")
    print ("send. buf size: " + socket.send_buf_size.to_s + "\n")
    print ("route_enabled: " + socket.route_enabled.to_s + "\n")
    print ("is_blocking: " + socket.is_blocking.to_s + "\n")
    print ("ok: " + ! socket.closed? + "\n")
    print ("expired_socket: " + socket.expired_socket.to_s + "\n")
    print ("dtable_full: " + socket.dtable_full.to_s + "\n")
    old_timeout = socket.timeout
    socket.set_timeout (1)
    print ("has_exception_state: " +
           socket.has_exception_state.to_s + "\n")
    socket.set_timeout(old_timeout)
    print ("is_linger_on: " + socket.is_linger_on.to_s + "\n")
    print ("is_out_of_band_inline: " +
           socket.is_out_of_band_inline.to_s + "\n")
    print ("linger_time: " + socket.linger_time.to_s + "\n")
    print ("no_buffers: " + socket.no_buffers.to_s + "\n")
    print ("not_connected: " + socket.not_connected.to_s + "\n")
=end
  end

  # Set `timing' to `arg'.
  pre  :arg_not_void do |arg| arg != nil end
  post :timing_set do |result, arg| timing == arg && timing != nil end
  def set_timing(arg)
    @timing = arg
    if timing then
      @timer = Timer.new
    else
      @timer = nil
    end
  end

  ##### Basic operations

  # Send `msg' to the server and put the server's response
  # into `server_response'.
  pre  :socket_ok do socket_ok end
  post :response_set_on_success do
    implies(last_communication_succeeded, server_response != nil) end
  def send_message(msg)
    if timing then
      timer.start
    end
    send_request(msg, true)
    if timing then
      print_timing_report
    end
  end

  # Send a request to terminate the server process.
  pre  :socket_ok do socket_ok end
  post :response_set_on_success do
    implies(last_communication_succeeded, server_response != nil) end
  def send_termination_request(wait_for_response)
    if timing then
      timer.start
    end
    send_request(Termination_message, wait_for_response)
    if timing then
      print_timing_report
    end
  end

  private

  ##### Implementation

  def end_of_message(s)
    @termination_requested = s[-1] == eot[0]
    result = @termination_requested || s[-1] == eom[0]
    result
  end

  attr_reader :timer

  def print_timing_report
    print("Last request/response took " +
           timer.elapsed_time.fine_seconds_count.to_s + " seconds.\n")
  end

  ##### Hook method implementations

  def timeout_value
    Timeout_seconds
  end

  ##### Implementation - Constants

  Buffersize = 1

  Seconds_in_an_hour = 60 * 60

  Seconds_in_a_day = Seconds_in_an_hour * 24

  Timeout_seconds = Seconds_in_a_day * 365

  Termination_message = "\n"

  ##### Unused

  Message_date_field_separator = ""

  Message_time_field_separator = ""

  def invariant
    # timer_exists_if_timing:
    (timing.nil? && timer.nil?) || (timing != nil && timer != nil)
  end

end

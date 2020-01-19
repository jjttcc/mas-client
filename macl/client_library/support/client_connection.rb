require 'socket'
require 'io/wait'
require 'basic_communication_protocol'
require 'socket_debugger'

# Client socket connections to a server
class ClientConnection
  include Contracts::DSL, BasicCommunicationProtocol

  public

  ##### Access

  # Host name of the server
  attr_reader :hostname

  # Port number of the server
  attr_reader :port_number

  # The socket used for communication with the server
  attr_reader :socket

  ##### Status report

  # Did the last communication with the server succeed?
  attr_reader :last_communication_succeeded

  # Last response from the server
  attr_reader :server_response

  # Report on last error if not `last_communication_succeeded'
  attr_reader :error_report

  # Is Current connected to the server?
  post :definition do |result|
    result == (socket != nil && ! socket.closed?) end
  def connected
    result = socket != nil && ! socket.closed?
  end

  # Is the socket "OK"?
  def socket_ok
    result = ! socket.closed?
  end

  private

  ##### Initialization

  # Make the connection, using the socket `skt'
  pre  :skt_exists do |skt| skt != nil end
  pre  :invariant do invariant end
  post :socket_set do |result, skt| socket != nil && socket == skt end
  post :connected_if_no_error do
    implies(last_communication_succeeded, connected) end
  post :invariant do invariant end
  def make_connected_with_socket(skt)
    @last_communication_succeeded = false
    @socket = skt
    # An exception will be thrown by this call if host/port
    # are invalid:
    make_socket_connected
    if ! socket.closed? then
      @last_communication_succeeded = true
    else
      @error_report = connection_failed_msg
    end
  rescue
    @error_report = Invalid_address_msg
  end

  # Set `hostname' and `port_number' to the specified values
  # and test the connection.  If the test fails (likely because
  # the address is invalid, the connection times out, or the
  # server can't be reached), an exception is thrown.
  pre  :invariant do invariant end
  post :host_port_set do hostname == host and port_number == port end
  post :invariant do invariant end
  def make_tested(host, port)
    @last_communication_succeeded = false
    @hostname = host
    @port_number = port
    @server_response = ""
    # Cause an exception to be thrown if host/port are invalid:
    @socket = initialized_socket(port_number, hostname)
    if ! socket.closed? then
      @last_communication_succeeded = true
      close
      @socket = nil
    else
      @error_report = connection_failed_msg
    end
  rescue
    @error_report = Invalid_address_msg
  end

  # Set `hostname' and `port_number' to the specified values
  # and establish a connection to the server.  If the connection
  # fails (likely because the address is invalid, the connection
  # times out, or the server can't be reached), an exception
  # is thrown.
  pre  :host_port do |host, port| ! (host.nil? || port.nil?) end
  pre  :invariant do invariant end
  post :host_port_set do |result, host, port|
    self.hostname == host && self.port_number == port end
  post :socket_exists_if_no_error do
    implies(last_communication_succeeded, socket != nil) end
  post :connected_if_no_error do
    implies(last_communication_succeeded, connected) end
  post :invariant do invariant end
  def make_connected(host, port)
    @last_communication_succeeded = false
    @hostname = host
    @port_number = port
    @server_response = ""
    @socket = nil
    # An exception will be thrown by this call if host/port
    # are invalid:
    make_socket_connected
    if ! socket.closed? then
      @last_communication_succeeded = true
    else
      @error_report = connection_failed_msg
    end
  rescue StandardError => e
    puts "#{self.class}.#{__method__} - error: #{e}\n#{caller.join("\n")}"
    @error_report = Invalid_address_msg
  end

  # Make `socket', connected to the server, with `port_number'
  # and `hostname'.  Don't 'create' socket if it is not Void.
  pre  :host_exists do hostname != nil end
  pre  :invariant do invariant end
  post :socket_exists do implies(connected, socket != nil) end
  post :invariant do invariant end
  def make_socket_connected
    if socket == nil then
      @socket = initialized_socket(port_number, hostname)
    end
    sdb = SocketDebugger.new(socket)
    if ! socket.closed? then
      # (Note: socket is "blocking" by default.)
      prepare_for_socket_connection
    end
  end

  private

  ##### Implementation

  # Send request `req' to the server and, if `wait_for_response',
  # place the server's response into `server_response'.
  pre  :r_exists do |req| req != nil end
  pre  :socket_exists do socket != nil end
  pre  :connected do connected end
  post :still_connected_if_no_error do
    implies(last_communication_succeeded, connected) end
  post :server_response_exists_if_wait_no_error do |rslt, req, wait_for_r|
    implies(wait_for_r && last_communication_succeeded,
            server_response != nil) end
  def send_request(req, wait_for_response)
    sdb = SocketDebugger.new(socket)
    @last_communication_succeeded = false
    @server_response = ""
    debug("sending request: <" + req + ">\n")
    socket.send(req, 0)
    if ! socket.closed? then
      @last_communication_succeeded = true
      if wait_for_response then
        receive_and_process_response
      end
    else
      @last_communication_succeeded = false
      @error_report = last_socket_error
    end
    debug "#{__method__} - server_response: #{self.server_response}"
  end

  # Send `req' to the server as a one-time-per-connection request
  # and, if `wait_for_response', place the server's response into
  # `server_response'.
  pre  :r_exists do |req| req != nil end
  post :not_connected do not connected end
  post :server_response_exists_if_no_error do
    implies(last_communication_succeeded, server_response != nil) end
  def send_one_time_request(req, wait_for_response)
    @last_communication_succeeded = false
    @socket = nil
    make_socket_connected
    if connected then
      send_request(req, wait_for_response)
    else
      @error_report = last_socket_error
    end
    close
  end

  # Process server response `s' - set `server_response' and
  # `last_communication_succeeded' accordingly.
  pre  :s_exists do |s| s != nil end
  post :server_response_set do server_response != nil end
  def process_response(s)
    # Default to simply assign `s' to `server_response' and
    # "succeed" - Redefine if needed.
    @server_response = s
    @last_communication_succeeded = true
  end

  # Close the connection.
  def close
    if socket != nil && ! socket.closed? then
      socket.close
    end
  end

  def last_socket_error
    result = socket.error
    if result.nil? then
      result = connection_failed_msg
    end
    result
  end

##### Implementation

  # Number of seconds client will wait for server to respond
  # before reporting a "timed-out" message
  def timeout_seconds
    deferred
  end

  # Does `c' indicate that the end of the data from the server
  # has been reached?
  def end_of_message(c)
    deferred
  end

  def connection_failed_msg
    result = "Connection to the " + server_type + "failed."
    if socket.error != nil && ! socket.error.is_empty then
      result = result + " (" + socket.error + ")"
    end
  end

  Invalid_address_msg = "Invalid network address."

  ##### Hook routines

  # Short description of the server
  def server_type
    result = "sever " # Redefine if needed - add a space at the end.
  end

  # A new socket initialized with `port' and `host'
  def initialized_socket(port, host)
=begin
relevant info/URLs:
https://spin.atomicobject.com/2013/09/30/socket-connection-timeout-ruby/
https://stackoverflow.com/questions/16383416/how-to-maintain-the-tcp-connection-using-ruby
https://www.scottklement.com/rpg/socktut/nonblocking.html
https://ruby-doc.com/docs/ProgrammingRuby/html/lib_network.html
=end
#!!!!!Note: Since Socket.tcp appears to be more flexible than TCPSocket
#!!!!!      (e.g., you can specify time-out on construction), I switched
#!!!!!      from
#!!!!!old:  TCPSocket.new(host, port)
#!!!!!      to:
    Socket.tcp(host, port, connect_timeout: timeout_value)
  end

  # Make any needed preparations before calling `socket.connect',
  # such as setting options on the `socket'.
  def prepare_for_socket_connection
    # null-op  -- Redefine if needed.
  end

  # Read response from the last request to the server and
  # place the result into `server_response'.
  pre  :last_communication_succeeded do
    ! socket.closed? && last_communication_succeeded end
  post :still_connected_if_no_error do
    implies(last_communication_succeeded, connected) end
  post :server_response_exists_if_no_error do
    implies(last_communication_succeeded, server_response != nil) end
  def receive_and_process_response
    s = socket.gets("")
    process_response(s)
  rescue SystemCallError => e
      @error_report = "Socket read failed: #{e}"
      @last_communication_succeeded = false
  end

  def timeout_value
    300
  end

  def invariant
    # server_response_exists_if_succeeded:
    implies last_communication_succeeded, server_response != nil
    # error_report_exists_on_failure:
    implies ! last_communication_succeeded, error_report != nil
    # socket_exists_if_connected:
    implies connected, socket != nil
  end

end

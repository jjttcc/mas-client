# Client socket connections to a server
class ClientConnection <

  BasicCommunicationProtocol

  public

  ##### Access

  hostname: STRING
      # Host name of the server

  port_number: INTEGER
      # Port number of the server

  socket: NETWORK_STREAM_SOCKET
      # The socket used for communication with the server

  ##### Status report

  last_communication_succeeded: BOOLEAN
      # Did the last communication with the server succeed?

  server_response: STRING
      # Last response from the server

  error_report: STRING
      # Report on last error if not `last_communication_succeeded'

  connected: BOOLEAN
      # Is Current connected to the server?
    do
      Result := socket /= Void and then
        socket.is_open_read and socket.is_open_write
    ensure
      definition: Result = (socket.is_open_read and socket.is_open_write)
    end

  socket_ok: BOOLEAN
      # Is the socket "OK"?
    do
       Result := socket.socket_ok
    end

private

##### Initialization

  make_connected_with_socket (skt: like socket)
      # Make the connection, using the socket `skt'
    require
      skt_exists: skt /= Void
    do
      last_communication_succeeded := false
      socket := skt
      # An exception will be thrown by this call if host/port
      # are invalid:
      make_socket_connected
      if socket.socket_ok then
        last_communication_succeeded := true
      else
        error_report := connection_failed_msg
      end
    ensure
      socket_set: socket /= Void and socket = skt
      connected_if_no_error: last_communication_succeeded implies
        connected
    rescue
      error_report := Invalid_address_msg
    end

  make_tested (host: STRING; port: INTEGER)
      # Set `hostname' and `port_number' to the specified values
      # and test the connection.  If the test fails (likely because
      # the address is invalid, the connection times out, or the
      # server can't be reached), an exception is thrown.
    do
      last_communication_succeeded := false
      hostname := host
      port_number := port
      server_response := ""
      # Cause an exception to be thrown if host/port are invalid:
      socket := initialized_socket (port_number, hostname)
      if socket.socket_ok then
        last_communication_succeeded := true
        close
        socket := Void
      else
        error_report := connection_failed_msg
      end
    ensure
      host_port_set: hostname = host and port_number = port
    rescue
      error_report := Invalid_address_msg
    end

  make_connected (host: STRING; port: INTEGER)
      # Set `hostname' and `port_number' to the specified values
      # and establish a connection to the server.  If the connection
      # fails (likely because the address is invalid, the connection
      # times out, or the server can't be reached), an exception
      # is thrown.
    do
      last_communication_succeeded := false
      hostname := host
      port_number := port
      server_response := ""
      socket := Void
      # An exception will be thrown by this call if host/port
      # are invalid:
      make_socket_connected
      if socket.socket_ok then
        last_communication_succeeded := true
      else
        error_report := connection_failed_msg
      end
    ensure
      host_port_set: hostname = host and port_number = port
      socket_exists_if_no_error: last_communication_succeeded implies
        socket /= Void
      connected_if_no_error: last_communication_succeeded implies
        connected
    rescue
      error_report := Invalid_address_msg
    end

  make_socket_connected
      # Make `socket', connected to the server, with `port_number'
      # and `hostname'.  Don't 'create' socket if it is not Void.
    require
      host_port_exist: hostname /= Void
local
sdb: SOCKET_DEBUGGER
    do
      if socket = Void then
        socket := initialized_socket (port_number, hostname)
      end
create sdb.make_with_socket (socket)
      if socket.socket_ok then
        socket.set_blocking
        socket.set_timeout (Timeout_seconds)
        prepare_for_socket_connection
--print ("socket report before request:%N" + sdb.report (Void) + "%N")
        socket.connect
--print ("socket report after request:%N" + sdb.report (Void) + "%N")
      end
    ensure
      blocking: connected implies socket.is_blocking and socket.socket_ok
      socket_exists: connected implies socket /= Void
    end

private

##### Implementation

  send_request (r: STRING; wait_for_response: BOOLEAN)
      # Send request `r' to the server and, if `wait_for_response',
      # place the server's response into `server_response'.
    require
      r_exists: r /= Void
      socket_exists: socket /= Void
      connected: connected
    local
      sdb: SOCKET_DEBUGGER
    do
      create sdb.make_with_socket (socket)
      last_communication_succeeded := false
      server_response := ""
      debug
        print ("socket report before request:%N" +
          sdb.report (Void) + "%N")
        print ("sending request: '" + r + "'%N")
      end
      socket.put_string (r)
      debug
        print ("socket report after request:%N" +
          sdb.report (Void) + "%N")
      end
      if socket.socket_ok then
        last_communication_succeeded := true
        if wait_for_response then
          receive_and_process_response
        end
      else
        last_communication_succeeded := false
        error_report := last_socket_error
      end
    ensure
      still_connected_if_no_error:
        last_communication_succeeded implies connected
      server_response_exists_if_wait_no_error: wait_for_response and
        last_communication_succeeded implies server_response /= Void
    end

  send_one_time_request (r: STRING; wait_for_response: BOOLEAN)
      # Send `r' to the server as a one-time-per-connection request
      # and, if `wait_for_response', place the server's response into
      # `server_response'.
    require
      r_exists: r /= Void
    do
      last_communication_succeeded := false
      socket := Void
      make_socket_connected
      if connected then
        send_request (r, wait_for_response)
      else
        error_report := last_socket_error
      end
      close
    ensure
      not_connected: not connected
      server_response_exists_if_no_error:
        last_communication_succeeded implies server_response /= Void
    end

  process_response (s: STRING)
      # Process server response `s' - set `server_response' and
      # `last_communication_succeeded' accordingly.
    require
      s_exists: s /= Void
    do
      # Default to simply assign `s' to `server_response' and
      # "succeed" - Redefine if needed.
      server_response := s
      last_communication_succeeded := true
    ensure
      server_response_set: server_response /= Void
    end

  close
      # Close the connection.
    do
      if socket /= Void and not socket.is_closed then
        socket.close
      end
    end

  last_socket_error: STRING
    do
      Result := socket.error
      if Result = Void then
        Result := connection_failed_msg
      end
    end

##### Implementation

  Timeout_seconds: INTEGER
      # Number of seconds client will wait for server to respond
      # before reporting a "timed-out" message
    deferred
    end

  end_of_message (c: CHARACTER): BOOLEAN
      # Does `c' indicate that the end of the data from the server
      # has been reached?
    deferred
    end

  connection_failed_msg: STRING
    do
      Result := "Connection to the " + server_type + "failed."
      if socket.error /= Void and not socket.error.is_empty then
        Result := Result + " (" + socket.error + ")"
      end
    end

  Invalid_address_msg: STRING = "Invalid network address."

##### Hook routines

  server_type: STRING
      # Short description of the server
    once
      Result := "sever " -- Redefine if needed - add a space at the end.
    end

  initialized_socket (port: INTEGER; host: STRING): like socket
      # A new socket initialized with `port' and `host'
    do
      create Result.make_client_by_port (port, host)
    end

  prepare_for_socket_connection
      # Make any needed preparations before calling `socket.connect',
      # such as setting options on the `socket'.
    do
      do_nothing  -- Redefine if needed.
    end

  receive_and_process_response
      # Read response from the last request to the server and
      # place the result into `server_response'.
    require
      last_communication_succeeded: socket.socket_ok and
        last_communication_succeeded
    local
      s: STRING
    do
      create s.make (0)
      if socket.ready_for_reading then
        from
          socket.read_character
        until
          end_of_message (socket.last_character)
        loop
          s.extend (socket.last_character)
          socket.read_character
        end
        if not socket.socket_ok then
          error_report := last_socket_error
        else
          process_response (s)
        end
      else
        error_report :=
          "Timed out waiting for server response."
        last_communication_succeeded := false
      end
    ensure
      still_connected_if_no_error:
        last_communication_succeeded implies connected
      server_response_exists_if_no_error:
        last_communication_succeeded implies server_response /= Void
    end

invariant

  server_response_exists_if_succeeded:
    last_communication_succeeded implies server_response /= Void
  error_report_exists_on_failure:
    not last_communication_succeeded implies error_report /= Void
  socket_exists_if_connected: connected implies socket /= Void

end

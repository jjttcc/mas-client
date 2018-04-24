#!/usr/bin/env ruby

# Non-blocking version of MasClientOptimized - i.e., sets timeouts for
# creating socket connections and socket reads to avoid long waits for these
# operations.  If a timeout occurs, a MasTimeoutError is raised; if a
# serious error, other than timeout, occurs, a MasRuntimeError is raised.
class MasClientNonblocking < MasClientOptimized

  public

  DEFAULT_TIMEOUT_SECONDS = 5

  attr_accessor :timeout

  private ## Redefinition of inherited methods

  def initialize_communication(host, port, close_after_w = false)
    super(host, port, close_after_w)
    @close_after_writing = close_after_w
    @timeout = DEFAULT_TIMEOUT_SECONDS
  end

  def initialize_timeout(timeout_in_seconds)
    @timeout = timeout_in_seconds
  end

  private

  # (Code borrowed from:
  #https://spin.atomicobject.com/2013/09/30/socket-connection-timeout-ruby/)
  def new_socket(h, p)
    if h == 'localhost' then
      # The tools used below don't like "localhost", for some reason.
      h="127.0.0.1"
    end
    # Convert the passed host into structures the non-blocking calls
    # can deal with.
    addr = Socket.getaddrinfo(h, nil)
    sockaddr = Socket.pack_sockaddr_in(p, addr[0][3])
    result = Socket.new(Socket.const_get(addr[0][0]),
                        Socket::SOCK_STREAM, 0).tap do |sockt|
$log.debug("[new_socket] [1]")
      sockt.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
$log.debug("[new_socket] [2]")
      begin
        # Initiate the socket connection in the background. If it doesn't fail
        # immediately, it will raise an IO::WaitWritable (Errno::EINPROGRESS)
        # indicating the connection is in progress.
$log.debug("[new_socket] [2a]")
        sockt.connect_nonblock(sockaddr)
$log.debug("[new_socket] [3]")
      rescue IO::WaitWritable
        # (Block until the socket is writable or the timeout is exceeded,
        # whichever comes first:)
$log.debug("[new_socket] [4] (timeout: #{timeout})")
        if IO.select(nil, [sockt], nil, timeout) then
          begin
            # Verify there is now a good connection
$log.debug("[new_socket] [5]")
            sockt.connect_nonblock(sockaddr)
          rescue Errno::EISCONN
$log.debug("[new_socket] [6]")
            # Success: socket is connected.
          rescue StandardError => e
$log.debug("[new_socket] [7], e: #{e}")
            # Connection failed due to an unexpected exception.
            sockt.close
            raise e, MasRuntimeError.new("Socket connection failed")
          end
$log.debug("[new_socket] [8]")
        else
$log.debug("[new_socket] [9]")
          # timed out (socket was not ready in time) [IO.select returned nil]
          sockt.close
          raise MasTimeoutError.new("Connection timeout #{timeout}")
        end
      rescue StandardError => e
$log.debug("[new_socket] [10], e: #{e}")
        raise e
      end
    end
$log.debug("[new_socket] [11] socket connected #{result.inspect}")
    result
  end

=begin
  def test_ssl_read_nonblock
    start_server(PORT, OpenSSL::SSL::VERIFY_NONE, true) { |server, port|
      sock = TCPSocket.new("127.0.0.1", port)
      ssl = OpenSSL::SSL::SSLSocket.new(sock)
      ssl.sync_close = true
      ssl.connect
      assert_raise(IO::WaitReadable) { ssl.read_nonblock(100) }
      ssl.write("abc\n")
      IO.select [ssl]
      assert_equal('a', ssl.read_nonblock(1))
      assert_equal("bc\n", ssl.read_nonblock(100))
      assert_raise(IO::WaitReadable) { ssl.read_nonblock(100) }
    }
  end
=end

  def socket_response
    result = ""
    first_try = true
    begin
      end_of_message = false
$log.debug("[socket_response] [1] - entering while loop")
      while not end_of_message do
        buf = @socket.read_nonblock(READ_LENGTH, exception: false)
$log.debug("[socket_response] [2] - buf: #{buf}")
        if buf == :wait_readable then
$log.debug("[socket_response] [3] (buf == :wait_readable, timeout[#{timeout}])")
          # No data is available yet (EAGAIN or EWOULDBLOCK) - wait for it
          if IO.select([@socket], nil, nil, timeout) then
$log.debug("[socket_response] [4]")
            # (Allow the next while-loop iteration to occur, during which
            # read_nonblock should get "actual data".)
          else
$log.debug("[socket_response] [5] - IO.select returned nil.")
            # timed out - server is not responding or connection hosed
#!!!!Should we close the socket?!!!!!
$log.debug("[socket_response] select timed out (#{timeout} seconds)")
            raise MasTimeoutError.new("Timed out while reading from MAS server")
          end
        else
$log.debug("[socket_response] [6] (buf != :wait_readable)")
          # Data IS available - "actual data"
          result << buf.to_s
          end_of_message = result[-1] == EOM
$log.debug("[socket_response] [7] - eom? - #{end_of_message}")
        end
      end
      $log.debug("[mco]received: '#{result[0..502]}...'")
    rescue EOFError       # (i.e., read_nonblock raised EOF)
$log.debug("[socket_response] [8]")
      $log.debug(self.class.to_s + ': EOF on read')
      if not end_of_message && first_try then
        # (EOF on initial read try and no "EOM" yet)
        first_try = false
        # EOF implies the server closed the connection, so open a new one:
        renew_socket
        $log.debug('[rec_resp] retrying...')
$log.debug("[socket_response] [9] (EOF - retrying)")
        retry
      end
    rescue RuntimeError => e
$log.debug("[socket_response] [10] timeout-error: #{e.inspect}")
      @socket.close
      raise e   # Pass on timeout error.
    rescue StandardError => e   # read_nonblock - read error
$log.debug("[socket_response] [11] error: #{e.inspect}")
$log.debug("[socket_response] [11a] stack:\n#{caller.join("\n")}")
      @socket.close
      raise e, "Error reading from MAS server"
    end
$log.debug("[socket_response] [12] result size: #{result.length}")
    result
  end

  def hideme_write_message(msg)
    bytes_written = 0
    msg_length = msg.length
$log.debug("[write_message] [1] - msg lnth: #{msg_length}")
    while bytes_written < msg_length do
      bytes = @socket.write_nonblock(READ_LENGTH, exception: false)
$log.debug("[write_message] [2] - bytes: #{bytes}")
      if bytes == :wait_writable then
$log.debug("[write_message] [3] - bytes == :wait_writable... selecting")
        # Can't write yet (EAGAIN or EWOULDBLOCK) - wait for it
        if IO.select(nil, [@socket], nil, timeout) then
$log.debug("[write_message] [4] - select said we're ready to write")
          # (Allow the next while-loop iteration to occur, during which
          # write_nonblock should actually be able write.)
        else
$log.debug("[write_message] [5] - Arghh!! - we timed out.")
          # timed out - server is not responding or connection hosed
          raise MasTimeoutError.new("Timed out while writing to MAS server")
        end
      else
$log.debug("[write_message] [6] - Wow!, we actually wrote #{bytes} bytes")
        # The write actually wrote - at least part of 'msg'.
        bytes_written += bytes
$log.debug("[write_message] [7] - bwritten: #{bytes_written}")
      end
    end
$log.debug("[write_message] [8] - We are out of loop, finished.")
  end

end

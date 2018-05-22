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
      sockt.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
      begin
        # Initiate the socket connection in the background. If it doesn't fail
        # immediately, it will raise an IO::WaitWritable (Errno::EINPROGRESS)
        # indicating the connection is in progress.
        sockt.connect_nonblock(sockaddr)
      rescue IO::WaitWritable
        # (Block until the socket is writable or the timeout is exceeded,
        # whichever comes first:)
        if IO.select(nil, [sockt], nil, timeout) then
          begin
            # Verify there is now a good connection
            sockt.connect_nonblock(sockaddr)
          rescue Errno::EISCONN
            # Success: socket is connected.
          rescue StandardError => e
            # Connection failed due to an unexpected exception.
            sockt.close
            raise e, MasRuntimeError.new("Socket connection failed")
          end
        else
          # timed out (socket was not ready in time) [IO.select returned nil]
          sockt.close
          raise MasTimeoutError.new("Connection timeout #{timeout}")
        end
      rescue StandardError => e
        raise e
      end
    end
    result
  end

  def socket_response
    result = ""
    first_try = true
    begin
      end_of_message = false
      while not end_of_message do
        buf = @socket.read_nonblock(READ_LENGTH, exception: false)
        if buf == :wait_readable then
          # No data is available yet (EAGAIN or EWOULDBLOCK) - wait for it
          if IO.select([@socket], nil, nil, timeout) then
            # (Allow the next while-loop iteration to occur, during which
            # read_nonblock should get "actual data".)
          else
            # timed out - server is not responding or connection hosed
            raise MasTimeoutError.new("Timed out while reading from MAS server")
          end
        else
          # Data IS available - "actual data"
          result << buf.to_s
          end_of_message = result[-1] == EOM || buf.empty?
        end
      end
      $log.debug("[mco]received: '#{result[0..502]}...'")
    rescue EOFError       # (i.e., read_nonblock raised EOF)
      $log.debug(self.class.to_s + ': EOF on read')
      if not end_of_message && first_try then
        # (EOF on initial read try and no "EOM" yet)
        first_try = false
        # EOF implies the server closed the connection, so open a new one:
        renew_socket
        $log.debug('[rec_resp] retrying...')
        retry
      end
    rescue RuntimeError => e
      @socket.close
      raise e   # Pass on timeout error.
    rescue StandardError => e   # read_nonblock - read error
      @socket.close
      raise e, "Error reading from MAS server"
    end
    result
  end

  #@@@This should either be removed, or completed/fixed and renamed to be
  #@@@used.
  def hideme_write_message(msg)
    bytes_written = 0
    msg_length = msg.length
    while bytes_written < msg_length do
      bytes = @socket.write_nonblock(READ_LENGTH, exception: false)
      if bytes == :wait_writable then
        # Can't write yet (EAGAIN or EWOULDBLOCK) - wait for it
        if IO.select(nil, [@socket], nil, timeout) then
          # (Allow the next while-loop iteration to occur, during which
          # write_nonblock should actually be able write.)
        else
          # timed out - server is not responding or connection hosed
          raise MasTimeoutError.new("Timed out while writing to MAS server")
        end
      else
        # The write actually wrote - at least part of 'msg'.
        bytes_written += bytes
      end
    end
  end

end

#!/usr/bin/env ruby

require 'socket'
require 'ruby_contracts'
require_relative 'mas_communication_services'


# MasClient, optimized to allow for an enhanced server that does not close
# the socket connection after each communication
class MasClientOptimized < MasClient

  private ## Redefinition of inherited methods

  def initialize_communication(host: host, port: port,
                               close_after_w: false)
    super(host: host, port: port)
    @close_after_writing = close_after_w
  end

  READ_LENGTH = 2**14

  def receive_response
    first_try = true
    begin
      @last_response = ''
      end_of_message = false
      while not end_of_message
#!!!!Consider using read_nonblock instead of readpartial (because it's
#!!!!nonblocking).
        buf = socket.readpartial(READ_LENGTH)
        @last_response << buf
        end_of_message = @last_response[-1] == EOM
      end
      @@log.debug("[mco]received: '#{last_response[0..52]}...'")
    rescue EOFError
      @@log.debug(self.class.to_s + ': EOF on read')
      if not end_of_message && first_try
        first_try = false
        # EOF implies the server closed the connection, so open a new one:
        renew_socket
        @@log.debug('[rec_resp] retrying...')
        retry
      end
    end
  end

  def send(msg)
    if socket == nil or server_closed_connection
      @@log.debug('[send] server_closed_connection...')
      renew_socket
    end
    @@log.debug("sending '#{msg}'")
    super(msg)
  end

  private

  # Assign 'socket' to a newly created TCPSocket.
  def renew_socket
    if socket != nil and not socket.closed?
      socket.close
    end
    @socket = TCPSocket.new(host, port)
  end

end

#!/usr/bin/env ruby

require 'socket'
require 'ruby_contracts'
require_relative 'mas_communication_services'


# MasClient, optimized to allow for an enhanced server that does not close
# the socket connection after each communication
class MasClientOptimized < MasClient

  private ## Redefinition of inherited methods

  def initialize_communication(host, port, close_after_w = false)
    super(host, port, close_after_w)
    @close_after_writing = close_after_w
  end

  READ_LENGTH = 2**14

  private # hook method redefinitions

  def post_initialize_communication(close_after_w)
    @close_after_writing = close_after_w
  end

  def prepare_for_send
    if socket == nil or server_closed_connection then
      $log.debug('[send] server_closed_connection...')
      renew_socket
    end
  end

  def socket_response
    result = ""
    first_try = true
    begin
      end_of_message = false
      while not end_of_message
        buf = socket.readpartial(READ_LENGTH)
        result << buf
        end_of_message = result[-1] == EOM
      end
      $log.debug("[mco]received: '#{result[0..502]}...'")
    rescue EOFError
      $log.debug(self.class.to_s + ': EOF on read')
      if not end_of_message && first_try then
        first_try = false
        # EOF implies the server closed the connection, so open a new one:
        renew_socket
        $log.debug('[rec_resp] retrying...')
        retry
      end
    end
    result
  end

  private

  # Assign 'socket' to a newly created TCPSocket.
  def renew_socket
    if socket != nil and not socket.closed? then
      socket.close
    end
    @socket = new_socket(host, port)
  end

end

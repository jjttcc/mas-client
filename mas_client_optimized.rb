#!/usr/bin/env ruby

require 'socket'
require 'ruby_contracts'
require_relative 'mas_communication_services'


# MasClient, optimized to allow for an enhanced server that does not close
# the socket connection after each communication
class MasClientOptimized < MasClient

  private ## Redefinition of inherited methods

  def initialize_communication(host, port, close_after_w = false)
    super(host, port)
    @close_after_writing = close_after_w
  end

  READ_LENGTH = 2**14

  def receive_response
    first_try = true
    begin
      @last_response = ''
      end_of_message = false
      while not end_of_message
        buf = socket.readpartial(READ_LENGTH)
        @last_response << buf
        end_of_message = @last_response[-1] == EOM
      end
      @@log.debug("[mco]received: '#{last_response[0..52]}'")
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

  private ####### old work-code - to be removed or reused

  def receive_response___old
    first_try = true
    begin
      @last_response = ''
      end_of_message = false
      while not end_of_message
        buf = socket.readpartial(READ_LENGTH)
        @last_response << buf
        end_of_message = @last_response[-1] == EOM
      end
    rescue EOFError
      @@log.debug(self.class.to_s + ': EOF on read')
      if first_try && (buf == nil || buf.length == 0)
        # Assume server has closed the socket connection, so open a new one.
        @@log.debug('[rec_resp] create new socket and retry')
        renew_socket
        first_try = false
        retry
      end
    end
  end

  def receive_response_old2
    first_try = true
    begin
      _, _, errors = IO.select(nil, nil, [socket], 0)
puts "A"
      if errors and errors.first
puts "B"
        p "<<<<<<<<rERRORS[1]:",  errors.first, ">>>>>>>>>>>"; exit 12
      end
puts "C"
      @last_response = ''
      end_of_message = false
      while not end_of_message
        buf = socket.readpartial(READ_LENGTH)
        @last_response << buf
        end_of_message = @last_response[-1] == EOM
      end
      @@log.debug("[mco]received:\n'#{last_response[0..52]}'")
puts "E"
    rescue EOFError
      @@log.debug(self.class.to_s + ': EOF on read')
      # Assume server has closed the socket connection, so open a new one.
      @@log.debug('[rec_resp] create new socket')
      renew_socket
      if first_try && (buf == nil || buf.length == 0)
        first_try = false
        @@log.debug('[rec_resp] retrying...')
        retry
      end
puts "F"
    end
  end

  def send_old(msg)
puts "send"
    _, _, errors = IO.select(nil, nil, [socket], 0)
    if errors and errors.first
      p "<<<<<<<<sERRORS[1]:", errors.first, ">>>>>>>>>>>"; exit 13
    end
    super(msg)
    @@log.debug("[mco]sent request: '#{msg}'")
    _, _, errors = IO.select(nil, nil, [socket], 0)
  rescue
    if errors and errors.first
      p "<<<<<<<<rERRORS[2]:",  errors.first, ">>>>>>>>>>>"; exit 12
    end
  end

  def begin_communication___remove_perhaps
#@@log.debug('[bc] started')
    if socket == nil
#@@log.debug('[bc] socket == nil: ' + (socket == nil).to_s)
    renew_socket
#@@log.debug('[bc] created new TCPSocket')
    else
#@@log.debug('[bc] doing nothing...')
    end
  end

  private ## Redefinition of inherited methods

  # Assign 'socket' to a newly created TCPSocket.
  def renew_socket
    if socket != nil and not socket.closed?
      socket.close
    end
    @socket = TCPSocket.new(host, port)
  end

end

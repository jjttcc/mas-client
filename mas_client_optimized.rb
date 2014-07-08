#!/usr/bin/env ruby

require 'socket'
require 'ruby_contracts'
require_relative 'mas_communication_services'


# MasClient, optimized to allow for an enhanced server that does not close
# the socket connection after each communication
class MasClientOptimized < MasClient

  private

  READ_LENGTH = 2**14

  def receive_response
    @last_response = ''
    end_of_message = false
    while not end_of_message
      buf = socket.readpartial(READ_LENGTH)
      @last_response << buf
      end_of_message = @last_response[-1] == EOM
    end
  rescue EOFError
    @@log.debug(self.class.to_s + ': EOF reached')
  end

  def begin_communication
    if socket == nil || socket.eof?
      if socket != nil then
        if ENV['VERBOSE']
          @@log.debug('[bc] socket!=nil; eof: ' + (socket.eof?).to_s)
        end
        socket.close
      end
      @socket = TCPSocket.new(@host, @port)
    end
  end

  def end_communication
  end

  private ## Hook routines

  def close_after_writing
    false
  end

end

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
    nil
    @@log.debug(self.class.to_s + ': EOF reached')
  end

  def receive_response_try3
    @last_response = ''
    end_of_message = false
    while buf = socket.readpartial(READ_LENGTH)
      @last_response << buf
    end
  rescue EOFError
    nil
  end

  def receive_response_try2
    @last_response = ''
    while buf = (socket.readpartial(READ_LENGTH) rescue nil)
      (@last_response||="") << buf
    end
  end

  def receive_response_try1
=begin
(from: http://coderrr.wordpress.com/2008/10/21/\
when-to-use-readpartial-instead-of-read-in-ruby/)
r, _, _ = IO.select([socket], nil, nil, 0)
data = r && r.first.read_nonblock(1024)
will not raise an exception (which is expensive if you're trying to do
this a couple of thousand times per second)
Comment by Theo (@iconara) — November 6, 2013 @ 11:07 am
Reply

sorry, should have been r && r.first && r.first.read_nonblock(1024)
=end

    @last_response = ''
    while @last_response[-1] != EOM
      ready, _, _ = IO.select([socket], nil, nil, 0)
      if ready && ready.first
        @last_response << ready.first.read_nonblock(READ_LENGTH)
@@log.debug('last_resp: ' + @last_response)
      else
        break
      end
    end
  end

  def begin_communication
    if socket == nil || socket.eof?
      @@log.debug("\n[begin_communication] " + self.class.to_s + ' - ' +
        ((socket != nil)? "eof: #{socket.eof?}" : 'NOT socket') +
        ' (creating new socket)')
      if socket != nil then socket.close end
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

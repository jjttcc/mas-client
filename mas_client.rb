#!/usr/bin/env ruby

require 'socket'
require 'ruby_contracts'
require_relative 'mas_communication_services'


# Clients that communicate via a TCP socket with the market-analysis server
class MasClient
  include MasCommunicationServices
  include Contracts::DSL

  public

  attr_reader :host, :port

  private

  attr_reader :socket

  def initialize_communication(port)
    @host = 'localhost'
    @port = port
  end

  def send(msg)
    @socket.write(msg)
    @socket.close_write
  end

  def receive_response
    @last_response = @socket.read
    #!!!!!!Note: Probably need to raise an exception if the read fails or the
    #!!!response is empty.
  end

  def begin_communication
    @socket = TCPSocket.new(@host, @port)
  end

  def end_communication
    @socket.close
  end

end

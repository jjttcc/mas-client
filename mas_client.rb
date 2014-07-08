#!/usr/bin/env ruby

require 'socket'
require 'logger'
require 'ruby_contracts'
require_relative 'mas_communication_services'


# Clients that communicate via a TCP socket with the market-analysis server
class MasClient
  include MasCommunicationServices
  include Contracts::DSL

  public

  attr_reader :host, :port

  private

  @@log = Logger.new(STDERR)

  attr_reader :socket

  def initialize_communication(port)
    @host = 'localhost'
    @port = port
  end

  def send(msg)
    socket.write(msg)
    if close_after_writing then socket.close_write end
  end

  def receive_response
    @last_response = socket.read
  end

  def begin_communication
    @socket = TCPSocket.new(@host, @port)
  end

  def end_communication
    socket.close
  end

  private ## Hook routines

  def close_after_writing
    true
  end

end

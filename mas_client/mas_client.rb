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

  attr_reader :host, :port, :close_after_writing

  protected

  attr_reader :socket

  private

  def initialize_communication(host, port, close_after_writing_dummy)
    @host = host
    @port = port
    @close_after_writing = true
  end

  def send(msg)
    socket.write(msg)
    if close_after_writing then socket.close_write end
  end

  def receive_response
    @last_response = socket.read
  end

  def begin_communication
    if socket == nil or close_after_writing
      @socket = TCPSocket.new(@host, @port)
    end
  end

  def end_communication
    if close_after_writing
      socket.close
    end
  end

  def finish_logout
    @socket = nil
  end

end
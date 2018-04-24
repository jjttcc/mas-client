#!/usr/bin/env ruby

require 'socket'
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

  def initialize_communication(host, port, close_after_writing)
    @host = host
    @port = port
    post_initialize_communication(close_after_writing)
  end

  def send(msg)
    prepare_for_send
    $log.debug("sending '#{msg}'")
    write_message(msg)
    if close_after_writing then
      $log.debug("[MasClient::send: close_after_writing=true - " +
                 "calling socket.close_write")
      socket.close_write
    else
      $log.debug("[MasClient::send: close_after_writing=false - " +
                 "doing nothing")
    end
  end

  def receive_response
    @last_response = socket_response
  end

  def begin_communication
    if socket == nil or close_after_writing then
      @socket = new_socket(@host, @port)
    end
  end

  def end_communication
    if close_after_writing then
      socket.close
    end
  end

  def finish_logout
    @socket = nil
  end

  private # (potential) hook methods

  def post_initialize_communication(close_after_writing)
    @close_after_writing = true
  end

  def new_socket(h, p)
      TCPSocket.new(h, p)
  end

  def prepare_for_send
  end

  def write_message(msg)
    socket.write(msg)
  end

  def socket_response
    socket.read
  end

end

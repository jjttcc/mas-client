#!/usr/bin/env ruby

require 'socket'
require 'ruby_contracts'
require_relative 'mas_communication_services'

FSEP_PTRN = Regexp.new("[	]")
#INITSTR = ""
INITSTR = "6	0	start_date	daily	now - 9 months	start_date	hourly	now - 2 months	start_date	30-minute	now - 55 days	start_date	20-minute	now - 1 month	start_date	15-minute	now - 1 month	start_date	10-minute	now - 18 days	start_date	5-minute	now - 18 days	start_date	weekly	now - 4 years	start_date	monthly	now - 8 years	start_date	quarterly	now - 10 years	end_date	daily	now\a"

class MasClient
  include MasCommunicationServices
  include Contracts::DSL

  public

  attr_reader :socket, :session_key, :symbols

  public

  # Request all available tradable symbols from the server and initialize the
  # 'symbols' attribute with this list.
  #type :in => String, :out => String
  #pre do |key| key != nil end
  pre do true end
  def request_symbols
    symreq = symbol_request(session_key)
puts "sending '#{symreq}'"
    @socket = TCPSocket.new(host, port)
    @socket.write(symreq)
    @socket.close_write
    result = @socket.read
    process_response(result)
    if response_ok?
      puts "Everything is OK!"
    else
      puts "Everything is NOT OK!!!!!"
      # !!!Handle the error...
    end
#puts "last_response_components: "
#p last_response_components
#puts "request_symbols got #{result}"
    @symbols = symbols_from_response
  end

  private

  attr_reader :host, :port

  def initialize(port)
    @host = 'localhost'
    @port = port
#puts "initmsg: '#{initial_message}'"; exit 29
    @socket = TCPSocket.new(@host, @port)
    @socket.write(initial_message)
    @socket.close_write
    result = @socket.read
    puts result
    process_response(result)
#!!!!This needs to be done in MasCommunicationServices:
##!!!!!!!!!!!!rm: parts = result.split(FSEP_PTRN)
#!!!!!!!!!response_code = Integer(parts[0])
    if response_ok?
      puts "Everything is OK!"
    else
      puts "Everything is NOT OK!!!!!"
      # !!!Handle the error...
    end
    @session_key = key_from_response
puts "session_key: #{session_key}"
  end
end

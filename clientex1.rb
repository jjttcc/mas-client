#!/usr/bin/env ruby

#require 'socket'
require_relative 'mas_client'

port = 2001
if ARGV.count > 0 then port = ARGV[0] end
puts "Using port #{port}"
client = MasClient.new(port)
puts client
puts "client session key: #{client.session_key}"
client.request_symbols
puts "returned list of symbols:"
p client.symbols

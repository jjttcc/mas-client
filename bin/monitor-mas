#!/usr/bin/env ruby

def usage
  puts "Usage: #{File.basename($0)} [<port>] [<hostname>]"
end

args = ARGV
ping = false
if args.count > 0 && args[0] =~ /-(p|ping)/
  ping = true
  args.shift
end
port = args[0]
host = nil
if args.count > 1
  host = args[1]
end
working_dir = File.dirname($0) + '/../test/'
mas_client_dir = File.dirname($0) + '/../mas_client'
config_dir = File.dirname($0) + '/../config'
$LOAD_PATH << mas_client_dir
$LOAD_PATH << config_dir
require 'mas_monitor.rb'
require 'mas_monitor_settings.rb'

settings = MasMonitorSettings.new(cwd: working_dir)
if host
  settings.host = host
end
if port
  settings.main_port = port
end
monitor = MasMonitor.new(settings: settings)

if ping
  if monitor.server_is_healthy
    puts "Server is doing fine."
    exit 0
  else
    puts "Server is dead or very unhappy."
    exit 3
  end
else
  monitor.run_forever
end

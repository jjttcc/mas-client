require 'logger'

if $logpath.nil? then
  $logpath = "/tmp/global.log#{$$}"
end

if $log.nil? then
  $log = Logger.new($logpath, 1, 1024000)
end

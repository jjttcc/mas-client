require 'logger'

if ! defined? $logpath then
  $logpath = "/tmp/global.log#{$$}"
end

if ! defined? $log then
  $log = Logger.new($logpath, 1, 1024000)
end

require 'logger'

if $log.nil? then
  $log = Logger.new("/tmp/mas-client.log#{$$}", 1, 1024000)
end

require 'ruby_contracts'

class MOTD
  include Contracts::DSL

  @@message_prefix = 'Current date and time: '

  pre do true end
  def message
    "#{@@message_prefix} #{Time.new.strftime("%Y-%m-%d %H:%M")}"
  end

end

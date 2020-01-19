require 'ruby_contracts'

class IO
  include Contracts::DSL

  public

  attr_reader :last_string

  def read_line
    @last_string = self.gets("\n")
  end

#from:
# https://stackoverflow.com/questions/930989/is-there-a-simple-method-for-checking-whether-a-ruby-io-instance-will-block-on-r/5022480#5022480
#!!!!!!(This appears to not work - If that's the case, remove it):
  def ready_for_read?
    result = IO.select([self], nil, nil, 0)
    result && (result.first.first == self)
  end

end

class Object
  include Contracts::DSL

  private

  MACL_DEBUG_ENVVAR = 'MACL_DEBUG'
  $DEBUGGING = false

  if ENV.has_key?(MACL_DEBUG_ENVVAR) then
    $DEBUGGING = true
  end

  public

  def deferred
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end

  # Assert the 'boolean_expression' is true - raise 'msg' if it is false.
  def check(boolean_expression, msg = nil)
    if msg.nil? then
      msg = "false assertion: '#{caller_locations(1, 1)[0].label}'"
    end
    if ! boolean_expression then
      raise msg
    end
  end

  # Is the specified string 's' a valid integer?
  post :false_if_empty do |result, s|
     implies(s.nil? || ! s.is_a?(String) || s.empty?, ! result) end
  def is_i?(s)
    s != nil && s.is_a?(String) && /\A[-+]?\d+\z/ === s
  end

  if $DEBUGGING then
    def debug(s = nil)
      if s != nil then
        if block_given? then
          print "#{s}: "
        else
          print "#{s}\n"
        end
      end
      if block_given? then
        puts yield
      end
    end
  else
    def debug(s = :optional); end
  end

end

class String
  include Contracts::DSL

  public

  # Remove all contents of 'self'.
  def clear_all
    self.slice!(0..-1)
  end

  def is_integer?
#    is_i?(self)
self != nil && self.is_a?(String) && /\A[-+]?\d+\z/ === self
#old:    self.to_i.to_s == self
  end

  def is_integer
    is_i?(self)
#old:    self.to_i.to_s == self
  end

  def is_real?
    /\A[+-]?\d+(\.[\d]+)?\z/.match(self)
  end

  alias_method :is_real, :is_real?

end

class MaclServerExitError < StandardError
  def initialize(msg = "[Server acknowledged user's exit request]")
    super
  end
end

require 'ruby_contracts'

class IO

  public

  attr_reader :last_string

  def read_line
    @last_string = self.gets("\n")
  end

end

class Object

  private

  MACL_DEBUG_ENVVAR = 'MACL_DEBUG'
  $DEBUGGING = false

  if ENV.has_key?(MACL_DEBUG_ENVVAR) then
    $DEBUGGING = true
  end

  def privatize_public_methods(o)
    o.instance_methods(false).each do |m|
      if o.public_method_defined?(m, false) then
        private m
      end
    end
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
# post :false_if_empty do |result, s|
#    implies(s.nil? || ! s.is_a?(String) || s.empty?, ! result) end
  def is_i?(s)
    s != nil && s.is_a?(String) && /\A[-+]?\d+\z/ === s
  end

  if $DEBUGGING then
    def debug(s = nil)
      if s != nil then
        if block_given? then
          $stderr.print "#{s}: "
        else
          $stderr.print "#{s}\n"
        end
      end
      if block_given? then
        puts yield
      end
    end
    def debugging_on?; true end
  else
    def debug(s = :optional); end
    def debugging_on?; false end
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
    self.is_a?(String) && /\A[-+]?\d+\z/ === self
  end

  alias_method :is_integer, :is_integer?

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

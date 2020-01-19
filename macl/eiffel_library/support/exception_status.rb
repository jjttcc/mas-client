require 'ruby_contracts'

# Extra exception status information (in addition to
# what is available in class EXCEPTIONS)
class ExceptionStatus
  include Contracts::DSL

  private

  ##### Initialization

  def initialize
    @description = ""
    check(invariant)
  end

  public

  ##### Access

  # Description of the cause of the exception
  attr_reader :description

  ##### Status report

  # Is the error condition that caused the exception considered fatal?
  attr_reader :fatal

  ##### Status setting

  # Set fatal to `arg'.
  post :fatal_set do |result, arg| fatal == arg end
  def set_fatal(arg)
    @fatal = arg
  end

  # Set description to `arg'.
  pre  :arg_good do |arg| arg != nil end
  post :description_set do |res, arg|
    description == arg && description != nil end
  def set_description (arg)
    @description = arg
  end

  def invariant
    description != nil
  end

end

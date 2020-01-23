require 'ruby_contracts'

# Command-line user interface functionality
module CommandLineUtilities
  include Contracts::DSL, GeneralUtilities

  privatize_public_methods(GeneralUtilities)

  protected

  # User-selected character
  def character_selection(msg)
      self.current_lines_read = 0
      if msg != Void && ! msg.empty? then
        print_list([msg, eom])
      end
      result = nil
      while result.nil? do
        read_line
        if last_string.count > 0 then
          result = last_string[0]
        end
      end
    end

  # User-selected string value
  post :result_exists do |result| result != nil end
  def string_selection(msg)
    self.current_lines_read = 0
    if msg != nil && ! msg.empty? then
      print_list([msg, " ", eom])
    end
    read_line
    result = last_string.clone
  end

  # Input/output media to which all input will be sent and
  # from which output will be received, respectively
  attr_accessor :input_device, :output_device # IO (or File, TCPSocket or ...?)

  ##### Input

  # Input a string and place it in `last_string'.
  def read_line
    read_input_line
    self.last_string = input_device.last_string
  end

  # Name of line-limit-reached exception
  Line_limit_reached = "Input line limit reached"

  # If `line_limit' is less than 0 or `current_lines_read' <
  # `line_limit', read the next line from `input_device'.
  # If `line_limit' is greater than 0 and `current_lines_read' >=
  # `line_limit', `current_lines_read' is set to 0 and an
  # exception is thrown.
  def read_input_line
    if line_limit < 0 || current_lines_read < line_limit then
      input_device.read_line
    else
      self.current_lines_read = 0
      raise (Line_limit_reached)
    end
    self.current_lines_read = current_lines_read + 1
  end

  ##### Miscellaneous

  protected

  ##### Implementation

  # Last integer input with `read_integer'
  attr_accessor :last_integer   # INTEGER

  # Last real input with `read_real'
  attr_accessor :last_double    # DOUBLE

  # Last string input with `read_line'
  attr_accessor :last_string    # STRING

  # Maximum number of lines that will be read - until
  # current_lines_read is reset to 0 - before a
  # `Line_limit_reached' exception is thrown - A value
  # less than 0 signifies no limit.
  def line_limit
    # Redefine to -1 for no line limit.
    result = 1000
  end

  # Current number of lines read in one input attempt
  attr_accessor :current_lines_read   # INTEGER

  # Redefinition of output method inherited from GENERAL to
  # send output to output_device
  def print(o)
    if o != nil then
      output_device.print(o)
    end
  end

  # End-of-message string - redefine if needed
  def eom
    debug("#{self.class}.#{__method__} returning empty string.]")
    ""
  end

  def invariant
    implies(line_limit >= 0, current_lines_read <= line_limit)
  end

end

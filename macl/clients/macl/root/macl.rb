require 'ruby_contracts'
require 'macl_command_line'
require 'command_line_utilities'

# Market Analysis Command-Line (MACL) client - accesses the
# MA server command-line interface via a socket connection.
class Macl
  include Contracts::DSL, CommandLineUtilities

  alias_method :output_message, :print

=begin
  CommandLineUtilities
    rename
      print as output_message
    export
      {NONE} all
      {ANY} deep_twin, is_deep_equal, standard_is_equal
    redefine
      output_device
    end
=end

=begin
  ExceptionServices
    rename
      print as output_message
    export
      {NONE} all
    undefine
      output_message
    redefine
      application_name
    end
=end

  private

  ##### Initialization

  def initialize
puts "a"
    processor = nil
    init_state
puts "b"
    processor = CommandProcessor.new(command_line.record)
puts "c"
    # Create the connection to  and start the conversation with
    # the server.
    connection = Connection.new
puts "d"
    connection.start_conversation(host, port)
puts "e"
    if command_line.timing_on then
      connection.set_timing (true)
    end
    while ! ( connection.termination_requested ||
             ! connection.last_communication_succeeded)
      print(connection.server_response)
      processor.process_server_msg(connection.server_response)
      handle_error(processor)
      processor.process_request(user_response)
      connection.send_message(processor.product)
      # Save the recorded input as it is entered to ensure the
      # output has been saved if an unrecoverable exception occurs.
      output_current_input_record(processor)
    end
    if ! connection.last_communication_succeeded then
      print(connection.error_report + "\n")
    end
    connection.close
    close_output_file(processor)
#  rescue
#    handle_fatal_exception
  end

  def init_state
puts "1"
    @command_line = MaclCommandLine.new
puts "2"
    not_verbose_reporting = true
puts "3"
    self.output_device = $stdout   #!!!!<- check!!!!
puts "3a - self.od - #{output_device}"
    if command_line.error_occurred then
puts "3b"
      print(command_line.error_description)
puts "3c"
      print(command_line.usage)
puts "3d"
      abort
    end
puts "4"
    if command_line.help then
      print (command_line.usage)
      exit(0)
    end
puts "5"
    if command_line.input_from_file then
      input_device = command_line.input_file
    else
      input_device = io.input
    end
puts "6"
    port = command_line.port_number
puts "7"
    if port == -1 then
      print (command_line.usage)
      abort ("Missing port number")
    end
puts "8"
    host = command_line.host_name
puts "9"
    if host.empty? then
      host = "localhost"
    end
puts "10"
  end

  private

  ##### Utilities

=begin
  abort (msg: STRING)
    do
      if msg != nil then
        print (msg + " - ")
      end
      exit_and_close_connection
      exit (-1)
    end
=end

  # Obtain user response, skipping comments (# ...) and
  # stripping off leading white space
  post :result_exists do |result| result != nil end
  def user_response
    finished = false
    result = ""
#    console: CONSOLE
    while !  finished do
      if not input_device.readable then
#          console ?= input_device
#          if console != nil then
#            abort ("End of input reached unexpectedly.")
#          else
        print ("End of input reached unexpectedly.\n"\
               "Attempting to return control to the console.\n")
        input_device = io.input
#          end
      end
      result = string_selection("")
      if ! result.empty? && result[0] != comment_character then
        finished = true
      end
      last_input_line_number = last_input_line_number + 1
      if command_line.is_debug then
        print ("\ninput line: " + last_input_line_number + "\n")
      end
    end
    result.left_adjust
  end

  # Exit and close the connection.
  def exit_and_close_connection
    print ("Exiting ...\n")
    if connection != nil and connection.socket_ok then
      connection.send_request(exit_string, false)
      connection.close
    end
  end

  def print(a)
    if command_line.quiet_mode then
      output_message(".")
      output_device.flush
    else
      output_message(a)
    end
  end

  def handle_fatal_exception
    retried = false
    begin
      if ! retried then
        print(abnormal_termination_message)
        last_exception_status.set_fatal(true)
        exit_and_close_connection
        if command_line.is_debug then
          handle_exception("")
        end
      end
      exit (1)
    rescue
      retried = true
      retry
    end
  end

  # If `processor.error', take appropriate action.
  # (processor: COMMAND_PROCESSOR)
  def handle_error (processor)
    if processor.error then
      if
        processor.fatal_error ||
          (command_line.terminate_on_error && command_line.input_from_file)
      then
        abort (Invalid_input_message)
      end
    end
  end

  # If `processor.record', output `processor.input_record' to
  # `command_line.output_file'.
  # (processor: COMMAND_PROCESSOR)
  pre  :processor_exists do |processor| processor != nil end
  post :input_saved_and_cleared do |r, processor|
    implies(processor.record, processor.input_record.empty?) end
  def output_current_input_record (processor)
    if processor.record then
      command_line.output_file.put_string (processor.input_record)
      command_line.output_file.flush
      processor.input_record.clear_all
    end
  end

  # If `processor.record', close `command_line.output_file'.
  # (processor: COMMAND_PROCESSOR)
  pre :processor_exists do |processor| processor != nil end
  pre :no_more_output do |processor|
    implies(processor.record, processor.input_record.empty?) end
  pre :output_file_open do |processor|
    implies(processor.record, ! command_line.output_file.is_closed) end
  def close_output_file (processor)
    if processor.record then
      print ("Saved recorded input to file " +
             command_line.output_file.name + ".\n")
      command_line.output_file.close
    end
  end

##### Attribute redefinitions

  attr_accessor :output_device    # PLAIN_TEXT_FILE

##### Implementation

  attr_reader :command_line   # MACL_COMMAND_LINE
  attr_reader :connection     # CONNECTION
  attr_reader :record_file    # PLAIN_TEXT_FILE

  def exit_string
    "x\n"
  end

  def comment_character
    '#'
  end

  attr_accessor :host, :port
  attr_accessor :last_input_line_number

  def application_name
    "client"
  end

  def abnormal_termination_message
    "\nUnexpected exception occurred.\n"
  end

  def invalid_input_message
    "\nInvalid or incorrect user input on line #{last_input_line_number.out}\n"
  end

end

require 'ruby_contracts'
#!!!!require 'exceptions'
require 'macl_command_line'
require 'command_line_utilities'
require 'exception_services'
require 'command_processor'
require 'connection'

# Market Analysis Command-Line (MACL) client - accesses the
# MA server command-line interface via a socket connection.
class Macl
  include Contracts::DSL, CommandLineUtilities, ExceptionServices

  alias_method :output_message, :print

=begin
  CommandLineUtilities
    rename
!!!check:      print as output_message
    export
!!!to-do:      {NONE} all
      {ANY} deep_twin, is_deep_equal, standard_is_equal
    redefine
      output_device
    end
=end

=begin
  ExceptionServices
    rename
!!!check:     print as output_message
    export
!!!to-do:      {NONE} all
    undefine
      output_message
    redefine
      application_name
    end
=end

  private

  attr_reader :processor

  ##### Initialization

  def initialize
    @processor = nil
    init_state
    @processor = CommandProcessor.new(command_line.record)
    # Create the connection to  and start the conversation with
    # the server.
    @connection = Connection.new(host, port)
    if command_line.timing_on then
      connection.set_timing (true)
    end
    while ! ( connection.termination_requested ||
             ! connection.last_communication_succeeded)
      print(connection.server_response)
      processor.process_server_msg(connection.server_response)
      handle_error
      processor.process_request(user_response)
      begin
        connection.send_message(processor.product)
      rescue Errno::EPIPE => e
        if reconnected_after_epipe then
          next
        else
          break #!!!!?????<-
        end
      end
      # Save the recorded input as it is entered to ensure the
      # output has been saved if an unrecoverable exception occurs.
      output_current_input_record
    end
    if ! connection.last_communication_succeeded then
      print("#{connection.error_report}\n")
    end
    connection.close
    close_output_file
  rescue MaclServerExitError => e
    puts e; exit 0
  rescue StandardError => e
    puts "ERROR: '#{e}' [#{e.class}] - exiting... stack:\n#{caller.join("\n")}"
    handle_fatal_exception
  end

  def init_state
    @command_line = MaclCommandLine.new
    @not_verbose_reporting = true
    self.output_device = $stdout
    if command_line.error_occurred then
      print(command_line.error_description)
      print(command_line.usage)
      abort
    end
    if command_line.help then
      print (command_line.usage)
      exit(0)
    end
    if command_line.input_from_file then
      self.input_device = command_line.input_file
    else
      self.input_device = $stdin
    end
    self.port = command_line.port_number
    if port == -1 then
      print (command_line.usage)
      abort ("Missing port number")
    end
    self.host = command_line.host_name
    if host.empty? then
      self.host = "localhost"
    end
  end

  private

  ##### Utilities

  def abort(msg)
    if msg != nil then
      print(msg + " - ")
    end
    exit_and_close_connection
    exit(-1)
  end

  # Obtain user response, skipping comments (# ...) and
  # stripping off leading white space
  post :result_exists do |result| result != nil end
  def user_response
    finished = false
    result = ""
    @last_input_line_number = 0
    while !  finished do
      result = string_selection("")
      if
        processor.empty_response_allowed ||
        (! result.empty? && result[0] != comment_character)
      then
        finished = true
      end
      @last_input_line_number = @last_input_line_number + 1
      if command_line.is_debug then
        print ("\ninput line: " + @last_input_line_number + "\n")
      end
    end
    result.strip
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
    rescue StandardError => e
      retried = true
      retry
    end
  end

  # If `processor.error', take appropriate action.
  def handle_error
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
  pre  :processor_exists do processor != nil end
  post :input_saved_and_cleared do
    implies(processor.record, processor.input_record.empty?) end
  def output_current_input_record
    if processor.record then
      command_line.output_file.print(processor.input_record)
      command_line.output_file.flush
      processor.input_record.clear_all
    end
  end

  # If `processor.record', close `command_line.output_file'.
  pre :processor_exists do processor != nil end
  pre :no_more_output do
    implies(processor.record, processor.input_record.empty?) end
  pre :file_open_if_record do
    ! processor.record || ! command_line.output_file.closed? end
  def close_output_file
    if processor.record then
      print ("Saved recorded input to file " +
             command_line.output_file.name + ".\n")
      command_line.output_file.close
    end
  end

  def reconnected_after_epipe
    result = false
    answer = string_selection("server closed connection - reconnect? ")
    if answer =~ /y/i then
      @connection = Connection.new(host, port)
      result = true
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
    "\nInvalid or incorrect user input on line #{last_input_line_number}\n"
  end

end

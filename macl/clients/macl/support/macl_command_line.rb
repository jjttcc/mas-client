require 'ruby_contracts'
require 'command_line'
require 'general_utilities'

# Parser of command-line arguments for Market Analysis
# Command-Line client application
class MaclCommandLine < CommandLine
  include Contracts::DSL, GeneralUtilities

  privatize_public_methods(GeneralUtilities)

  public

  ##### Access

  # Message: how to invoke the program from the command-line
  def usage
    result = "Usage: " + command_name + " [options] port_number" +
      "\nOptions:\n" +
      "   -h <hostname>   Connect to server on Host <hostname>\n" +
      "   -r <file>       Record user input and save to <file>\n" +
      "   -i <file>       Obtain Input from <file> instead of " +
      "the console\n" +
      "   -terminate      Terminate execution if an error is " +
      "encountered\n" +
      "   -timing         Time each request/response to/from " +
      "the server\n" +
      "   -q              Quiet mode - suppress output - for " +
      "use with -i\n" +
      "   -debug          Debug mode - print input line numbers\n" +
      "   -?              Print this help message and exit\n" +
      "   -v              Print version and exit\n"
  end

  ##### Access -- settings

  # host name of the machine on which the server is running
  attr_reader :host_name    # STRING

  # Port number of the server socket connection: -1 if not set
  attr_reader :port_number    # INTEGER

  # Should user input be recorded?
  attr_reader :record   # BOOLEAN

  # Is the input to be read from a file?
  attr_reader :input_from_file    # BOOLEAN

  # The output file for recording
  attr_reader :output_file    # PLAIN_TEXT_FILE

  # The input file when `input_from_file'
  attr_reader :input_file   # PLAIN_TEXT_FILE

  # Should the process be terminated if an error occurs?
  attr_reader :terminate_on_error   # BOOLEAN

  # Are communications with the server to be timed?
  attr_reader :timing_on    # BOOLEAN

  # Run in quiet mode - suppress output?
  attr_reader :quiet_mode   # BOOLEAN

  ##### Status report

  # Has `symbol_list' been initialized?
  attr_reader :symbol_list_initialized    # BOOLEAN

  private

  ##### Implementation - Hook routine implementations

  def ambiguous_characters
    ['t']
  end

  def prepare_for_argument_processing
    @port_number = -1
    @host_name = ""
  end

  def finish_argument_processing
    @initialization_complete = true
  end

  ##### Implementation

  def help_string
    'H'
  end

  def debug_string
    "deb"
  end

  # Set `host_name' and remove its settings from `contents'.
  def set_host_name
    index = option_in_contents('h')
    if index >= 0 then
      if contents[index].length > 2 then
        @host_name = contents[index][2..-1]
        # Delete the host-name setting from (CL argument) contents:
        contents.delete_at(index)
        @last_argument_found = true
      else
        # Delete the '-h' from (CL argument) contents:
        contents.delete_at(index)
        @last_argument_found = true
        @host_name = contents[index]
        # Delete the host-name setting from (CL argument) contents:
        contents.delete_at(index)
      end
    elsif self.host_name.nil? then
      @error_occurred = true
      log_errors([Hostname_error])
    end
  end

  # Set `port_number' and remove its settings from `contents'.
  def set_port_number
    (0 .. contents.count - 1).each do |i|
      if contents[i].is_integer? then
        @port_number = contents[i].to_i
        contents.delete_at(i)
        @last_argument_found = true
        break
      end
    end
  end

  # Set `record' and `output_file' and remove their settings
  # from `contents'.
  def set_record_settings
    if output_file != nil then
      if option_in_contents('r') >= 0 then
        log_errors([too_many_output_files_error])
      end
    else
      index = option_in_contents('r')
      if index >= 0 then
        if contents[index].length > 2 then
          @record = true
          # (Exclude "-r" [e.g., in '-rinput-file']:)
          file_name = contents[index][2..-1]
          contents.delete_at(index)
          @last_argument_found = true
        else
          contents.delete_at(index)
          @last_argument_found = true
          if contents.count >= index then
            @record = true
            file_name = contents[index]
            contents.delete_at(index)
          else
            check(! record, "not_recording")
            @error_occurred = true
            log_errors([output_file_error])
          end
        end
      end
    end
    if output_file.nil? && record then
      @output_file = File.new(file_name, "w")
    end
  rescue StandardError => e
    @error_occurred = true
    @record = false
    if
      file_name != nil && FileTest.exist?(file_name) &&
        ! FileTest.writable?(file_name)
    then
      log_errors(["File", file_name.to_s, "is not writable. (#{e})\n"])
    else
      log_errors(["Error: #{e}"])
    end
  end

  def set_input_from_file_settings
    index = option_in_contents('i')
    if index >= 0 then
      if input_file != nil then
        log_errors ([Too_many_input_files_error])
      elsif contents[index].length > 2 then
        @input_from_file = true
        file_name = contents[index][2..-1]
        contents.delete_at(index)
        @last_argument_found = true
      else
        contents.delete_at(index)
        @last_argument_found = true
        if contents.count >= index then
          @input_from_file = true
          file_name = contents[index]
          contents.delete_at(index)
        else
          # not_file_input:
          check(! input_from_file)
          @error_occurred = true
          log_errors ([Input_file_error])
        end
      end
    end
    if input_file.nil? && input_from_file then
      @input_file = File.new(file_name, "r")
    end
  rescue StandardError => e
    @error_occurred = true
    @input_from_file = false
    log_errors(["Error: opening #{file_name}: #{e}"])
  end

  def set_terminate_on_error
    #!!!!!![TBI]!!!!!!
  end

=begin
#!!!!!old:
  set_terminate_on_error
    do
      if option_string_in_contents ("te") then
        terminate_on_error := true
        contents.remove
        @last_argument_found = true
      end
    end
=end

  def set_timing_on
    index = option_string_in_contents("ti")
    if index >= 0 then
      @timing_on = true
      contents.delete_at(index)
      @last_argument_found = true
    end
  end

  def set_quiet_mode
    index = option_in_contents('q')
    if index >= 0 then
      @quiet_mode = true
      contents.delete_at(index)
      @last_argument_found = true
    end
  end

  ##### Implementation queries

  # List of the set_... procedures that are called
  # unconditionally - for convenience
  # (LINKED_LIST [PROCEDURE [ANY, TUPLE []]])
  def main_setup_procedures
    [
      self.method(:set_host_name),
      self.method(:set_port_number),
      self.method(:set_record_settings),
      self.method(:set_input_from_file_settings),
      self.method(:set_terminate_on_error),
      self.method(:set_timing_on),
      self.method(:set_quiet_mode),
      self.method(:set_debug)
    ]
  end

  attr_reader :initialization_complete    # BOOLEAN

  ##### Implementation - Constants

  def output_file_error
    "Output file for -r option was not specified.\n"
  end

  def input_file_error
    "Input file for -i option was not specified.\n"
  end

  def too_many_input_files_error
    "Input file (-i option) was specified more than once.\n"
  end

  def too_many_output_files_error
    "Output file (-r option) was specified more than once.\n"
  end

  Hostname_error = "Host name for -h option was not specified.\n"

  def Debug_string
    "deb"
  end

  ##### ERROR_SUBSCRIBER interface

  def notify(s)
    @error_occurred = true
    @error_description = s
  end

=begin
invariant

  host_name_exists: not error_occurred implies host_name /= Void
  output_file_exists_if_recording: not error_occurred implies 
    (record implies output_file /= Void and output_file.is_open_write)
  input_file_exists_if_input_from_file: not error_occurred implies 
    (input_from_file implies input_file /= Void and
    input_file.is_open_read)
=end

end

require 'command_line'
require 'general_utilities'

# Parser of command-line arguments for Market Analysis
# Command-Line client application
class MaclCommandLine < CommandLine
=begin
    redefine
      help_character, ambiguous_characters, debug_string
    end
=end

  include GeneralUtilities

=begin
  GeneralUtilities
    export
      {NONE} all
    end
=end

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
      "   -?              Print this help message\n"
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

=begin
  ambiguous_characters: LINEAR [CHARACTER]
    local
      a: ARRAY [CHARACTER]
    once
      a := <<'t'>>
      result := a.linear_representation
    end
=end

  def prepare_for_argument_processing
    @port_number = -1
    @host_name = ""
  end

  def finish_argument_processing
    @initialization_complete = true
  end

##### Implementation

  def help_character
    'H'
  end

  # Set `host_name' and remove its settings from `contents'.
  def set_host_name
    index = option_in_contents('h')
    if index >= 0 then
      if contents[index].count > 2 then
        @host_name = contents[index][2..-1]
        contents.delete_at(index)
        @last_argument_found = true
      else
        @last_argument_found = true
        @host_name = contents[index]
        contents.delete_at(index)
      end
    else
      @error_occurred = true
      log_errors([Hostname_error])
    end
  end

=begin
#!!!!!old:
  set_host_name
      -- Set `host_name' and remove its settings from `contents'.
    do
      if option_in_contents ('h') then
        if contents.item.count > 2 then
          create host_name.make (contents.item.count - 2)
          host_name.append (contents.item.substring (
            3, contents.item.count))
          contents.remove
          last_argument_found := True
        else
          contents.remove
          last_argument_found := True
          if not contents.exhausted then
            create host_name.make (contents.item.count)
            host_name.append (contents.item)
            contents.remove
          else
            error_occurred := True
            log_errors (<<Hostname_error>>)
          end
        end
      end
    end
=end

  # Set `port_number' and remove its settings from `contents'.
  def set_port_number
    (0 .. contents.count - 1).each do |i|
      if contents[i].is_integer? then
        port_number = contents[i].to_i
        contents.delete_at(i)
        @last_argument_found = true
        break
      end
    end
  end

=begin
#!!!!!old:
  set_port_number
      # Set `port_number' and remove its settings from `contents'.
    do
      from
        contents.start
      until
        contents.exhausted
      loop
        if contents.item.is_integer then
          port_number := contents.item.to_integer
          contents.remove
          @last_argument_found = true
        else
          contents.forth
        end
      end
    end
=end

  def set_record_settings
    #!!!!!![TBI]!!!!!!
  end

=begin
#!!!!!old:
  set_record_settings
      # Set `record' and `output_file' and remove their settings
      # from `contents'.
    local
      file_name: STRING
    do
      if output_file /= Void then
        log_errors (<<Too_many_output_files_error>>)
      elseif option_in_contents ('r') then
        if contents.item.count > 2 then
          record := true
          create file_name.make (contents.item.count - 2)
          file_name.append (contents.item.substring (
            3, contents.item.count))
          contents.remove
          @last_argument_found = true
        else
          contents.remove
          @last_argument_found = true
          if not contents.exhausted then
            record := true
            create file_name.make (contents.item.count)
            file_name.append (contents.item)
            contents.remove
          else
            check
              not_recording: not record
            end
            @error_occurred = true
            log_errors (<<output_file_error>>)
          end
        end
      end
      if output_file = Void and record then
        create output_file.make (file_name)
        if not output_file.exists or else output_file.is_writable then
          output_file.open_write
        else
          check
            file_exists_and_is_not_writable:
              output_file.exists and not output_file.is_writable
          end
          @error_occurred = true
          record := false
          log_errors (<<"File ", output_file.name,
            " is not writable.\n">>)
        end
      end
    end
=end

  def set_input_from_file_settings
    #!!!!!![TBI]!!!!!!
  end

=begin
#!!!!!old:
  set_input_from_file_settings
      # Set `input_from_file' and `input_file' and remove their
      # settings from `contents'.
    local
      file_name: STRING
    do
      if option_in_contents ('i') then
        if input_file /= Void then
          log_errors (<<Too_many_input_files_error>>)
        elseif contents.item.count > 2 then
          input_from_file := true
          create file_name.make (contents.item.count - 2)
          file_name.append (contents.item.substring (
            3, contents.item.count))
          contents.remove
          @last_argument_found = true
        else
          contents.remove
          @last_argument_found = true
          if not contents.exhausted then
            input_from_file := true
            create file_name.make (contents.item.count)
            file_name.append (contents.item)
            contents.remove
          else
            check
              not_file_input: not input_from_file
            end
            @error_occurred = true
            log_errors (<<Input_file_error>>)
          end
        end
      end
      if input_file = Void and input_from_file then
        create input_file.make (file_name)
        if input_file.exists and then input_file.is_readable then
          input_file.open_read
        else
          @error_occurred = true
          input_from_file := false
          if not input_file.exists then
            log_errors (<<"File ", input_file.name,
              " does not exist.\n">>)
          else
            log_errors (<<"File ", input_file.name,
              " is not readable.\n">>)
          end
        end
      end
    end
=end

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

=begin
#!!!!!old:
  set_timing_on
    do
      if option_string_in_contents ("ti") then
        timing_on := true
        contents.remove
        @last_argument_found = true
      end
    end
=end

  def set_quiet_mode
    index = option_in_contents('q')
    if index >= 0 then
      @quiet_mode = true
      contents.delete_at(index)
      @last_argument_found = true
    end
  end

=begin
#!!!!!old:
  set_quiet_mode
    do
      if option_in_contents ('q') then
        quiet_mode := true
        contents.remove
        @last_argument_found = true
      end
    end
=end

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

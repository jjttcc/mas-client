require 'ruby_contracts'

# Generic parser of command-line arguments for an application
class CommandLine
  include Contracts::DSL

  private

  ##### Initialization

  def initialize
    @error_description = ""
    @contents = ARGV.dup
    prepare_for_argument_processing
    check_for_ambiguous_options
    process_arguments(initial_setup_procedures)
    process_arguments(main_setup_procedures)
    finish_argument_processing
    check_for_invalid_flags
  end

  public

  ##### Access

  # Has the user requested help on command-line options?
  # true if "-h" or "-?" is found.
  attr_reader :help   # BOOLEAN

  # Has the user requested the version number?
  # true if "-v" is found.
  attr_reader :version_request    # BOOLEAN

  # Has "debug" mode been specified?
  attr_reader :is_debug   # BOOLEAN

  # Did an error occur while processing options?
  attr_reader :error_occurred   # BOOLEAN

  # Description of error, if available
  attr_reader :error_description    # STRING

  # Message: how to invoke the program from the command-line
  def usage
    deferred
  end

  def command_name
    File.basename($0)
  end

  ##### Basic operations

  # Print `usage' message.
  def print_usage
    print(usage)
  end

  # Check for invalid arguments - that is, items in
  # `contents' that begin with '-' that remain after the valid
  # arguments have been processed and removed from `contents'.
  pre :error_description_exists do error_description != nil end
  def check_for_invalid_flags
    flags = remaining_flags
    if not flags.empty? then
      @error_occurred = true
      flags.each do |f|
        @error_description += "Invalid option: " + f + "\n"
      end
    end
  end

  private

  ##### Implementation - argument processing

  def process_arguments(setup_procedures)
    # Continue running each member of setup_procedures until no more
    # arguments for that procedure are found.
    setup_procedures.each do |p|
      @last_argument_found = false
      debug "#{__method__} calling #{p}"
      p.call()
      until ! @last_argument_found || contents.empty? do
        @last_argument_found = false
        p.call()
      end
      if contents.empty? then
        break   # No more arguments to process/parse.
      end
    end
  end

  # Setup procedures used to process arguments
  # (LINEAR [PROCEDURE [ANY, TUPLE []]])
  def initial_setup_procedures
    # a: ARRAY [PROCEDURE [ANY, TUPLE []]]
    a = [self.method(:set_help), self.method(:set_version_request)]
    result = a
  end

  # Was the last argument processed by a 'setup procedure' found
  # in the argument list?
  attr_reader :last_argument_found    # BOOLEAN

  ##### Implementation - Hook routines

  # Do any needed preparations before processing arguments.
  def prepare_for_argument_processing
    deferred
  end

  # Do any needed cleanup after processing arguments.
  def finish_argument_processing
    deferred
  end

  # Setup procedures used to process arguments
  # (LINKED_LIST [PROCEDURE [ANY, TUPLE []]])
  def main_setup_procedures
    deferred
  end

  def ambiguous_characters
    # Default to an empty list.
    []
  end

  # Handle the ambiguous option.
  def handle_ambiguous_option(c)
    # Redefine if different behavior is needed.
    @error_occurred = true
    @error_description = Ambiguous_option_message + ': "' + c + '"' + "\n"
  end

  ##### Implementation

  attr_reader :contents   # LINKED_LIST [STRING]

  def help_string
    deferred
  end

  Question_mark = '?'

  def set_help
    index = option_in_contents(help_string)
    if index >= 0 then
      @help = true
      @last_argument_found = true
      contents.delete_at(index)
    else
      if help_string != Question_mark then
        index = option_in_contents("\\" + Question_mark)
      end
      if index >= 0 then
        @help = true
        @last_argument_found = true
        contents.delete_at(index)
      end
    end
  end

  def set_version_request
    index = option_in_contents('v')
    debug "#{__method__} - index: #{index}"
    if index >= 0 then
      @version_request = true
      @last_argument_found = true
      contents.delete_at(index)
    end
    debug "#{__method__} - version_request: #{version_request}"
  end

  def set_debug
    #!!!!!![TBI]!!!!!!
  end

=begin
#!!!!!old:
  set_debug
      # Set `is_debug' to true and remove the item that contains
      # the debug setting from `contents' iff `contents' contains
      # "-" + Debug_string or "--" + Debug_string.  Descendant must
      # explicitly call this routine if the debugging state is desired.
    do
      if option_in_contents (Debug_string @ 1) then
        if
          contents.item.substring_index ("-" + Debug_string, 1) = 1
          or
          contents.item.substring_index ("--" + Debug_string, 1) = 1
        then
          is_debug := true
          @last_argument_found = true
          contents.remove
        end
      end
    end
=end

  # The index of the first element of the 'contents' array that holds
  # the specified option flag/character
  # -1 if 'o' is not found in 'contents'
  def option_in_contents(o)
    result = -1
    (0 .. contents.count - 1).each do |i|
      if contents[i] =~ /^--?#{o}/i then
        result = i
        break
      end
    end
    debug do
      if result > -1 then
        "#{__method__} - FOUND IT: #{result}, #{contents[result]}"
      end
    end
    result
  end

  alias_method :option_string_in_contents, :option_in_contents

  # Does `c' occur in `contents' as a one-character option
  # (e.g., "-x")?
  def one_character_option(c)
    index = option_in_contents(c)
    if index >= 0 then
      result = contents[index] == "-#{c.to_s}" ||
      contents[index] == "--#{c.to_s}"
    end
  end

  # Check for ambiguous options
  def check_for_ambiguous_options
    ambiguous_characters.each do |c|
      if one_character_option(c) then
        handle_ambiguous_option(c)
        i = option_in_contents(c)
        if i >= 0 then
          contents.delete_at(i)
        end
      end
    end
  end

  # Arguments remaining in `contents' that begin with '-' -
  # Intended to be used to find invalid arguments after the valid
  # arguments have been processed and removed from `contents'.
  post :result_exists do |result| result != nil end
  def remaining_flags
    result = []
    contents.each do |s|
      if s[0] == '-' then
        result << s
      end
    end
  end

  ##### Implementation - Constants

  def debug_string
    "debug"
  end

  Ambiguous_option_message = "Ambiguous option"

end

require 'ruby_contracts'

# Generic parser of command-line arguments for an application
class CommandLine
  include Contracts::DSL

=begin
  ARGUMENTS
    export
      {NONE} all
      {ANY} deep_twin, is_deep_equal, standard_is_equal
    end
=end

  private

  ##### Initialization

  def initialize
puts "i"
    @error_description = ""
    @contents = ARGV.dup
puts "ii - errocc: #{error_occurred}"
    prepare_for_argument_processing
puts "iii - errocc: #{error_occurred}"
    check_for_ambiguous_options
puts "iv - errocc: #{error_occurred}"
    process_arguments(initial_setup_procedures)
puts "v - errocc: #{error_occurred}"
    process_arguments(main_setup_procedures)
puts "vi - errocc: #{error_occurred}"
    finish_argument_processing
puts "vii - errocc: #{error_occurred}"
    check_for_invalid_flags
puts "viii - errocc: #{error_occurred}"
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
      flags.start
      @error_description += "Invalid option: " + flags.item + "\n"
#     from
        flags.forth
      while ! flags.exhausted do
        @error_description += "Invalid option: " + flags.item + "\n"
        flags.forth
      end
    end
  end

  private

  ##### Implementation - argument processing

  def process_arguments(setup_procedures)
    # Continue running setup_procedures.item until no more
    # arguments for that procedure are found.
    setup_procedures.each do |p|
puts "#{__method__} - p: #{p}, errocc: #{self.error_occurred}, laf: #{@last_argument_found}"
      @last_argument_found = false
      p.call()
puts "#{__method__} - a, errocc: #{self.error_occurred}, laf: #{@last_argument_found}"
      until ! last_argument_found do
puts "#{__method__} - b, errocc: #{self.error_occurred}, laf: #{@last_argument_found}"
        @last_argument_found = false
        p.call()
      end
puts "#{__method__} - c, errocc: #{self.error_occurred}, laf: #{@last_argument_found}"
    end
puts "#{__method__} - d, errocc: #{self.error_occurred}, laf: #{@last_argument_found}"
  end

=begin
#!!!!old:
  process_arguments (setup_procedures: LINEAR [PROCEDURE [ANY, TUPLE []]])
    do
      from
        setup_procedures.start
      until
        setup_procedures.exhausted
      loop
        # Continue running setup_procedures.item until no more
        # arguments for that procedure are found.
        from
          @last_argument_found = false
          setup_procedures.item.call ([])
        until
          not last_argument_found
        loop
          @last_argument_found = false
          setup_procedures.item.call ([])
        end
        setup_procedures.forth
      end
    end
=end

  # Setup procedures used to process arguments
  # (LINEAR [PROCEDURE [ANY, TUPLE []]])
  def initial_setup_procedures
    # a: ARRAY [PROCEDURE [ANY, TUPLE []]]
    a = [self.method(:set_help), self.method(:set_version_request)]
##!!!!      result = a.linear_representation
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

=begin
  handle_ambiguous_option
      # Handle the ambiguous option in `contents.item'.
    do
      # Redefine if different behavior is needed.
      @error_occurred = true
      @error_description = Ambiguous_option_message + ": %"" +
        contents.item + "%"%N"
    end
=end

##### Implementation

  attr_reader :contents   # LINKED_LIST [STRING]

  def help_character
    'h'
  end

  Question_mark = '?'

  def set_help
#!!!!Check this call - it's likely broken:!!!!!
    index = option_in_contents(help_character)
    if index >= 0 then
      @help = true
      @last_argument_found = true
      contents.delete_at(index)
    else
      if help_character != Question_mark then
        index = option_in_contents(Question_mark)
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
    if index >= 0 then
      @version_request = true
      @last_argument_found = true
      contents.delete_at(index)
    end
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
      if contents[i] =~ /^--?#{o}/ then
        result = i
        break
      end
    end
    result
  end

  ###!!!!![experiment!!!!!]!!!!!!!###
  alias_method :option_string_in_contents, :option_in_contents

=begin
#!!!!old:
  option_in_contents (c: CHARACTER): BOOLEAN
    do
      from
        contents.start
      until
        contents.exhausted or Result
      loop
        if
          (contents.item.count >= 2 and
            contents.item.item(1).is_equal(option_sign) and
            contents.item.item(2).is_equal(o)) or
            # Allow GNU "--opt" type options:
          (contents.item.count >= 3 and
            contents.item.item(1).is_equal(option_sign) and
            contents.item.item(2).is_equal(option_sign) and
            contents.item.item(3).is_equal(o))
        then
          Result := true
        else
          contents.forth
        end
      end
    ensure
      cursor_set_if_true: Result = (not contents.exhausted and then
        ((contents.item.item(1).is_equal(option_sign) and
          contents.item.item(2).is_equal(o)) or
        (contents.item.item(1).is_equal(option_sign) and
          contents.item.item(2).is_equal(option_sign) and
          contents.item.item(3).is_equal(o))))
      exhausted_if_false: not Result = contents.exhausted
    end
=end

=begin
  option_string_in_contents (s: STRING): BOOLEAN
      # Is option `c' in `contents'?
    local
      scount: INTEGER
    do
      from
        scount := s.count
        contents.start
      until
        contents.exhausted or Result
      loop
        if
          (contents.item.count >= scount + 1 and
          contents.item.item (1) = option_sign and
          contents.item.substring (2, scount + 1).is_equal (s)) or
            # Allow GNU "--opt" type options:
          (contents.item.count >= scount + 2 and
          contents.item.item (1) = option_sign and
          contents.item.item (2) = option_sign and
          contents.item.substring (3, scount + 2).is_equal (s))
        then
          Result := true
        else
          contents.forth
        end
      end
    ensure
      Result implies (contents.item.item (1) = option_sign and
        contents.item.substring (2, s.count + 1).is_equal (s)) or
        (contents.item.item (1) = option_sign and
        contents.item.item (2) = option_sign and
        contents.item.substring (3, s.count + 2).is_equal (s))
    end

  one_character_option (c: CHARACTER): BOOLEAN
      # Does `c' occur in `contents' as a one-character option
      # (e.g., "-x")?
    do
      Result := option_in_contents (c)
      if Result then
        Result := contents.item.is_equal ("-" + c.out) or
          contents.item.is_equal ("--" + c.out)
      end
    end
=end

  # Check for ambiguous options
  def check_for_ambiguous_options
    ambiguous_characters.each do |c|
      if one_character_option(c) then
        handle_ambiguous_option
        contents.remove
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

=begin
#!!!!orig:
  remaining_flags: LINKED_LIST [STRING]
      # Arguments remaining in `contents' that begin with '-' -
      # Intended to be used to find invalid arguments after the valid
      # arguments have been processed and removed from `contents'.
    do
      from
        create Result.make
        contents.start
      until
        contents.exhausted
      loop
        if contents.item @ 1 = '-' then
          Result.extend (contents.item)
        end
        contents.forth
      end
    ensure
      result_exists: Result /= Void
    end
=end

##### Implementation - Constants

  def debug_string
    "debug"
  end

  def ambiguous_option_message
    "Ambiguous option"
  end

end

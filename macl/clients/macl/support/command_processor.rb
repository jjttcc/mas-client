require 'ruby_contracts'
require 'regular_expression_utilities'
#!!!!require 'exceptions'

# Objects responsible for processing user-supplied commands
class CommandProcessor
  private
  include Contracts::DSL, RegularExpressionUtilities, GeneralUtilities

=begin
###!!!!!!delete these lines soon:
    RegularExpressionUtilities
        rename match as re_match end
=end

=begin
    GeneralUtilities
        export
            {NONE} all
        end
=end

  private

  ##### Initialization

  def initialize(rec)
    self.record = rec
    self.input_record = ""
    self.fatal_error = false
    self.error = false
#!!!!!!!!!Check if the change from ".*" to '.*' yields correct behavior:
    self.select_patterns = [
      'Select[^?]*function',
      'Select[^?]*opera[nt][do]',
      'Select *an *indicator *for.*\'s',
      'Select *indicator *to *view',
      'Select *an *object *for.*\'s',
      'Select *the *[a-z]* *technical indicator',
      'Select *an *indicator *to *edit:',
      '^Added type.*\.$',
      '^User was created with the following properties:',
      'has.*leaf.*function.*-.*',
      '^Examining.*leaf.*function.*',
      'Select *the.*trading *period *type.*:',
      'Select specification for crossover detection:',
      'Select *a *market *analyzer',
      'Indicator *\'.*\' *children:',
      # Built to match "1) word\n.*" but not match
      # "1) word   2) word.*":
#!!!!!!!CHECK THIS FIX:
# command_processor.rb:151:in `match': unmatched close parenthesis: /^1) [^)]*$/ (RegexpError)
      '^1\) [^)]*$'
    ]
    # match: "(Hit <Enter> to restart the command-line client.)":
    self.exit_pattern = /Hit.{0,3}Enter.{0,6}restart/i
    # match: "(Hit <Enter> to continue ...)"
    self.continue_pattern = /Hit.{0,3}Enter.{0,6}continue/i
    self.objects = {}         # String, String
    self.shared_objects = {}  # String, String
    # Note: @objects.compare_objects
    # Note: @shared_objects.compare_objects
  end

  public

  ##### Access

  # The processed user request to be sent to the server
  attr_reader :product    # STRING

  # Recorded input
  attr_reader :input_record   # STRING

  # Has the server implied that an empty/blank response is OK?
  attr_reader :empty_response_allowed

  ##### Status report

  # Is input and output to be recorded?
  attr_reader :record         # BOOLEAN

  attr_reader :fatal_error    # BOOLEAN
  attr_reader :error          # BOOLEAN

  ##### Basic operations

  # Process the message `s' from the server - if it includes
  # an object selection list, save the list for processing.
  pre :s_exists do |s| s != nil end
  def process_server_msg(s)
    self.fatal_error = false
    self.error = false
    self.server_response_is_selection_list = false
    if s.match(exit_pattern) then
      raise MaclServerExitError
#      puts "IT IS TIME TO SAY GOODBYE."
#      #!!!!!!!CHECK: Should this exit happen here???:
#      exit 0
    elsif s.match(continue_pattern) then
      self.empty_response_allowed = true
    end
    if invalid_pattern_match(s) then
      # Server responded with "invalid input" message.
      self.error = true
    end
    if object_selection_match(s) then
      self.server_response_is_selection_list = true
      store_objects_from_selection_list(s)
    end
  end

  # Process the request, `r', to send to the server according to
  # the stored object choice.  If there is no current choice,
  # `product' will equal `r'; else `product' will be the
  # specified choice, if there is a match.  If there is no
  # match, fatal_error will be true.
  pre :r_exists do |r| r != nil end
  post :product_exists do self.product != nil end
  def process_request(r)
    @product = ""
    shared, key_matched = false, false
    work_string = ""
    otable = nil
    work_string = r
    if match(Shared_pattern, r) then
      otable = shared_objects
      debug("process: Using shared list\n")
      debug("very verbose: #{otable.inspect}\n#{otable}")
      work_string = sub(Shared_pattern, "", r)
      debug("process: after sub - work_string: #{work_string}\n")
      shared = true
    else
      otable = objects
    end
    debug("process: Checking '#{work_string}' with:\n")
    debug("very verbose: #{otable.inspect}\n#{otable}")
    if server_response_is_selection_list then
      if otable.has_key?(work_string) then
        @product = otable[work_string]
        debug("process: Matched: #{product}")
        key_matched = true
      else
        # No match via "conventional" attempts, so try to
        # "fudge" a bit:
        @product = attempted_rematch(work_string, otable)
        if not product.equal?(work_string) then
          key_matched = true
        end
      end
    else
      @product = work_string
      debug("process: No match: #{product}")
    end
    if record then
      record_input(product, shared, key_matched)
    end
    @product = product + "\n"
  end

  private

  ##### Implementation

  # Does `s' match one of `select_patterns'?
  def object_selection_match(s)
    debug(:osm) { "\nChecking for match of '#{s}'" }
    patterns = select_patterns
    matching_pattern = nil
    patterns.each do |p|
      debug(" (with '#{p}')")
      if s.match(p) then
        matching_pattern = p
        debug("MATCHED - with '#{matching_pattern}')")
        break
      end
    end
    debug(:osm) { "\nreturning result of #{matching_pattern != nil}" }
    matching_pattern != nil
  end

  # Extract each "object" name and associated selection number
  # from `s' and store this pair as key (number) and value
  # (name) in either `objects' or `shared_objects' according
  # to whether or not the "object" is shared.
  def store_objects_from_selection_list(s)
    objects.clear; shared_objects.clear
    # Ensure that DOS-based text can be properly split on
    # a newline by removing the carriage return:
    s.delete("\r")
    lines = s.split ("\n")
    lines.each do |l|
      debug("sc") do
        "l: '" + l + "'\n"
      end
      if match(Selection_list_pattern, l) then
        if match(Two_column_selection_list_pattern, l) then
          process_2_column_selection_line(objects, l)
        else
          # It's just a one-column selection list.
          process_selection_line(objects, l)
        end
      elsif match(Non_shared_pattern, l) && objects.count > 0 then
        # `l' indicates that the remaining items
        # (lines) constitute the list of "non-shared objects".
        # This means that `objects', which contains the
        # already processed `lines', holds the list of
        # "shared objects", so adjust the contents of
        # 'shared_objects' and 'objects' accordingly.
        shared_objects = objects.clone
        objects.clear
      end
    end
  end

  # Process `s', according to `shared' (`s' matched
  # `Shared_pattern') and `key_match' (a key associated with
  # `s' was contained in an object table) and append the
  # result to `input_record'.
  def record_input(s, shared, key_match)
    debug ("ri") do
      "ri - s, shared, key_match: '" + s + "', " +
             shared.to_s + ", " + key_match.to_s
    end
    if server_response_is_selection_list then
      if key_match then
        if shared then
          self.input_record = self.input_record + Shared_string + s + "\n"
        else
          self.input_record = self.input_record + s + "\n"
        end
      elsif objects.has_value?(s) then
        debug ("ri") do
          s + " in objects\n"
        end
        self.input_record = self.input_record + objects.key(s) + "\n"
      elsif shared_objects.has_value?(s) then
        debug ("ri") do
          s + " in shared objects\n"
        end
        self.input_record = self.input_record + Shared_string +
          shared_objects.key(s) + "\n"
      else
        debug ("ri") do
          "adding " + s + " to input record\n"
        end
        self.input_record = self.input_record + s + "\n"
      end
    else
      debug ("ri") do
        "adding " +  s + " to input record\n"
      end
      self.input_record = self.input_record + s + "\n"
    end
  end

  # Attempt to match `phrase' with a key in obj_table and, if a
  # match is found, return the associated value from obj_table.
  # If no match is found, return `phrase'.
  pre  :existence do |phrase, obj_table| phrase != nil && obj_table != nil end
  post :not_void do |result| result != nil end
  def attempted_rematch(phrase, obj_table)
    matches = fuzzy_matches(phrase, obj_table.keys, 2)
    if matches.empty? then
      result = phrase
    else
      result = obj_table[matches[0]]
      if result.length > 1 then
        log_error("attempted_rematch could not narrow down (" +
                  result.length.to_s + " matches)")
      end
    end
    debug("process") do
      log_error("attempted_rematch returning '" + result + "'\n")
    end
    result
  end

  ##### Implementation - Regular expressions

  # Does `target' match an "invalid" pattern?
  def invalid_pattern_match(target)
    result = one_pattern_matches(INVALID_PATTERNS, target)
  end

  ##### Implementation - Utilities

  # Process the current `line' (from a selection list received
  # from the server): Extract the "object number" and "object
  # name" and insert this pair into `obj_table', where "object
  # number" is the key and "object name" is the data item.
  def process_selection_line(obj_table, line)
    work_string = sub(/\)/, "", line)
    objnumber = sub(/ .*/, "", work_string)
    objname = sub(/^[^ ]*  */, "", work_string)
    # Strip off trailing spaces:
    objname = sub(/[ \t]*$/, "", objname)
    obj_table[objname] = objnumber
    debug ("sc") do
      "Stored: #{obj_table[objname]} (#{objname})\n"
    end
  end

  # Process the current `line' (from a selection list received
  # from the server) as a line from a two-column selection list:
  # For each column: extract the "object number" and "object
  # name" and insert this pair into `obj_table', where "object
  # number" is the key and "object name" is the data item.
  def process_2_column_selection_line(obj_table, line)
    if match("^([0-9]+\).*)[ \t]+([0-9]+\).*)[ \t]*", line) then
#!!!!!!!FIX: convert to use ruby Regexp capture mechanism:
      item1 = last_regular_expression.captured_substring(1)
      item2 = last_regular_expression.captured_substring(2)
      process_selection_line(obj_table, item1)
      process_selection_line(obj_table, item2)
    else
      $stderr.print("Defect: object selection match failed to " +
                    "match line:\n" + line +
                    "\nPlease report this bug bug to the MAS developers.\n")
      self.fatal_error = true
      self.error = true
    end
  end

  # "fuzzy" matches, if any, of `phrase' with `attempted_target_set'
  # If no match is found, result is empty.
  pre  :existence do |phrase, attempted_target_set|
    phrase != nil && attempted_target_set != nil end
  pre  :sane_limit do |phr, ats, char_compare_limit|
    char_compare_limit >= 0 && char_compare_limit <= SANE_CHAR_LIMIT end
  post :result_exists do |result| result != nil end
  def fuzzy_matches(phrase, attempted_target_set, char_compare_limit)
    new_limit = 0
    result = []
    # (Put matches into result.)
    attempted_target_set.each do |s|
      if phrase[0..char_compare_limit - 1] == s[0..char_compare_limit - 1] then
        result << s
        debug("process") do
          log_error("[fuzz] found match: " + s + "\n")
        end
      end
    end
    if result.count > 1 then
      previous_matches = result
      new_limit = char_compare_limit + 1
      if new_limit <= SANE_CHAR_LIMIT then
        # Recursively attempt to narrow the matches
        result = fuzzy_matches(phrase, result, new_limit)
        if result.count == 0 then
          # (2+ matches are better than 0.)
          result = previous_matches
        end
      end
    end
    result
  end

  ##### Implementation - "Attributes"

  attr_writer :product, :input_record
  attr_writer :record
  attr_writer :fatal_error, :error

  # Is the last processed server response an
  # "object-selection-list"?
  attr_accessor :server_response_is_selection_list    # BOOLEAN

  # Patterns for invalid or incorrect input
  INVALID_PATTERNS = ["Invalid selection", "Selection must be between"]

  Non_shared_pattern = ".*List of valid non.shared objects:.*"

  # Pattern indicating that the user response indicates a
  # "shared" object
  Shared_pattern = "shared *"

  # String used to label a user response as specifying a
  # "shared" object
  Shared_string = "shared "

  # Regular-expression patterns used to determine if
  # an "object-selection-list" is being presented to the user
  attr_accessor :select_patterns    # ARRAY [STRING]

  # Pattern indicating the server has received an exit ("x") request
  attr_accessor :exit_pattern

  # Pattern indicating the "Hit <Enter> to continue" server response:
  attr_accessor :continue_pattern

  attr_writer   :empty_response_allowed

  # Unshared objects listed in the last "object-selection-list"
  attr_accessor :objects            # HASH_TABLE [STRING, STRING]

  # Shared objects listed in the last "object-selection-list"
  attr_accessor :shared_objects     # HASH_TABLE [STRING, STRING]

  # Pattern indicating that the server has sent a "selection list"
#!!!instead of:  Selection_list_pattern = "^[1-9][0-9]*\)"
#!!!try [not sure yet - more testing/debugging needed!!!!!]:
Selection_list_pattern = '^[1-9][0-9]*\)'

  # Pattern indicating that the server has sent a 2-column
  # "selection list"
#!!!instead of:  Two_column_selection_list_pattern = "^[1-9][0-9]*\).*[ \t][1-9][0-9]*\)"
#!!!try [not sure yet - more testing/debugging needed!!!!!]:
  Two_column_selection_list_pattern = '^[1-9][0-9]*\).*[ \t][1-9][0-9]*\)'

  SANE_CHAR_LIMIT = 100

end

require 'ruby_contracts'

# Objects responsible for processing user-supplied commands
class CommandProcessor
  include Contracts::DSL

=begin
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

  def initialize(rec: BOOLEAN)
    record = rec
    input_record = ""
    fatal_error = false
    error = false
    select_patterns = ["Select[^?]*function",
                        "Select[^?]*opera[nt][do]",
                        "Select *an *indicator *for.*'s",
                        "Select *indicator *to *view",
                        "Select *an *object *for.*'s",
                        "Select *the *[a-z]* *technical indicator",
                        "Select *an *indicator *to *edit:",
                        "^Added type.*\.$",
                        "^User was created with the following properties:",
                        "has.*leaf.*function.*-.*",
                        "^Examining.*leaf.*function.*",
                        "Select *the.*trading *period *type.*:",
                        "Select specification for crossover detection:",
                        "Select *a *market *analyzer",
                        "Indicator *%".*%" *children:",
                        # Built to match "1) word\n.*" but not match
                        # "1) word   2) word.*":
                        "^1\) [^)]*$"]
    @objects = {}         # String, String
    @shared_objects = {}  # String, String
    # Note: @objects.compare_objects
    # Note: @shared_objects.compare_objects
  end

  public

  ##### Access

  # The processed user request to be sent to the server
  attr_reader :product    # STRING

  # Recorded input
  attr_reader :input_record   # STRING

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
    fatal_error = false
    error = false
    server_response_is_selection_list = false
    if invalid_pattern_match (s) then
      # Server responded with "invalid input" message.
      error = true
    end
    if object_selection_match (s) then
      server_response_is_selection_list = true
      store_objects_from_selection_list (s)
    end
  end

  # Process the request, `r', to send to the server according to
  # the stored object choice.  If there is no current choice,
  # `product' will equal `r'; else `product' will be the
  # specified choice, if there is a match.  If there is no
  # match, fatal_error will be true.
  pre :r_exists do |r| r != nil end
  post :product_exists do product != nil end
  def process_request (r: STRING)
    shared, key_matched = false, false
    work_string = ""
    otable = nil
    work_string = r
    if match(shared_pattern, r) then
      otable = shared_objects
#!!!! [need to define 'debug']
      debug("process: Using shared list\n")
      debug("very verbose: #{otable.current_keys}\n#{otable}")
      #!!!! [sub = r.e. substitution]
      work_string = sub(shared_pattern, "", r)
      debug("process: after sub - work_string: #{work_string}\n")
      shared = true
    else
      otable = objects
    end
    debug("process: Checking '#{work_string}' with:\n")
    debug("very verbose: #{otable.current_keys}\n#{otable}")
    if server_response_is_selection_list then
      if otable.has(work_string) then
        product = otable[work_string]
        debug("process: Matched: #{product}")
        key_matched = true
      else
        # No match via "conventional" attempts, so try to
        # "fudge" a bit:
        product = attempted_rematch(work_string, otable)
        if not equal(product, work_string) then
          key_matched = true
        end
      end
    else
      product = work_string
      debug("process: No match: #{product}")
    end
    if record then
      record_input(product, shared, key_matched)
    end
    product = product + "\n"
  end

  private

  ##### Implementation

  # Does `s' match one of `select_patterns'?
  def object_selection_match(s)
    result = false
    debug("osm: %NChecking for match of '#{s}'%N")
    patterns = select_patterns.linear_representation
    patterns.start
    while ! (result or patterns.exhausted) do
      debug("osm: with '#{patterns.item}'%N")
      if match (patterns.item, s) then
        result = true
      else
        patterns.forth
      end
    end
    debug("osm: %Nreturning result of #{result}")
    if result then
      print (" (with '" + patterns.item + "')%N")
    else
      print ("%N")
    end
  end

    store_objects_from_selection_list (s: STRING)
            # Extract each "object" name and associated selection number
            # from `s' and store this pair as key (number) and value
            # (name) in either `objects' or `shared_objects' according
            # to whether or not the "object" is shared.
        local
            lines: LIST [STRING]
        do
            objects.wipe_out; shared_objects.wipe_out
            # Ensure that DOS-based text can be properly split on
            # a newline by removing the carriage return:
            s.prune_all ('%R')
            lines = s.split ('%N')
            from
                lines.start
            until
                lines.exhausted
            loop
                debug ("sc")
                    print ("lines.item: '" + lines.item + "'%N")
                end
                if
                    match (selection_list_pattern, lines.item)
                then
                    if
                        match (two_column_selection_list_pattern, lines.item)
                    then
                        process_2_column_selection_line (objects, lines.item)
                    else
                        # It's just a one-column selection list.
                        process_selection_line (objects, lines.item)
                    end
                elseif
                    match (non_shared_pattern, lines.item) and
                    objects.count > 0
                then
                    # `lines.item' indicates that the remaining items
                    # (lines) constitute the list of "non-shared objects".
                    # This means that `objects', which contains the
                    # already processed `lines', holds the list of
                    # "shared objects", so adjust the contents of
                    # shared_objects and objects accordingly.
                    shared_objects = objects.twin
                    objects.wipe_out
                end
                lines.forth
            end
        end

    record_input (s: STRING; shared, key_match: BOOLEAN)
            # Process `s', according to `shared' (`s' matched
            # `shared_pattern') and `key_match' (a key associated with
            # `s' was contained in an object table) and append the
            # result to `input_record'.
        do
            debug ("ri")
                print ("ri - s, shared, key_match: '" + s + "', " +
                    shared.out + ", " + key_match.out)
            end
            if server_response_is_selection_list then
                if key_match then
                    if shared then
                        input_record = input_record +
                            shared_string + s + "%N"
                    else
                        input_record = input_record + s + "%N"
                    end
                elseif objects.has_item (s) then
                    debug ("ri")
                        print (s + " in objects%N")
                    end
                    input_record = input_record + key_for (s, objects) + "%N"
                elseif shared_objects.has_item (s) then
                    debug ("ri")
                        print (s + " in shared objects%N")
                    end
                    input_record = input_record + shared_string +
                        key_for (s, shared_objects) + "%N"
                else
                    debug ("ri")
                        print ("adding " + s + " to input record%N")
                    end
                    input_record = input_record + s + "%N"
                end
            else
                debug ("ri")
                    print ("adding " +  s + " to input record%N")
                end
                input_record = input_record + s + "%N"
            end
        end

    key_for (s: STRING; objs: HASH_TABLE [STRING, STRING]): STRING
            # The key in `objs' for item `s'
        local
            l: LINEAR [STRING]
        do
            result = ""
            l = objs.current_keys.linear_representation
            from
                l.start
            until
                l.exhausted
            loop
                if (objs @ l.item).is_equal (s) then
                    result = l.item
                end
                l.forth
            end
            debug ("kf")
                print ("key_for returning " + result + "%N")
            end
        end

    attempted_rematch(phrase: STRING;
        obj_table: HASH_TABLE [STRING, STRING]): STRING
            # Attempt to match `phrase' with a key in obj_table and, if a
            # match is found, return the associated value from obj_table.
            # If no match is found, return `phrase'.
        require
            existence: phrase /= Void and then obj_table /= Void
        local
            matches: ARRAY [STRING]
        do
            matches = fuzzy_matches(phrase, obj_table.current_keys, 2)
            if matches.is_empty then
                result = phrase
            else
                result = obj_table @ (matches @ 1)
                if result.count > 1 then
                    log_error("attempted_rematch could not narrow down (" +
                        result.count.out + " matches)")
                end
            end
            debug ("process")
                log_error("attempted_rematch returning '" + result + "'%N")
            end
        ensure
            not_void: result /= Void
        end

##### Implementation - Regular expressions

    match (pattern, s: STRING): BOOLEAN
            # Does `s' match the regular expression `pattern'?
        do
            result = re_match (pattern, s)
            if last_compile_failed then
                io.error.print (
                    "Defect: regular expression compilation failed.%N")
                io.error.print (last_regular_expression.error_message +
                    "%N(position: " +
                    last_regular_expression.error_position.out +
                    "%NPlease report this bug bug to the MAS developers.%N")
                fatal_error = true
                error = true
            end
        ensure
            last_regular_expression_exists: last_regular_expression /= Void
        end

    invalid_pattern_match (target: STRING): BOOLEAN
            # Does `target' match an "invalid" pattern?
        do
            result = one_pattern_matches (
                INVALID_PATTERNS.linear_representation, target)
        end

##### Implementation - Utilities

    process_selection_line (obj_table: HASH_TABLE [STRING, STRING];
        line: STRING)
            # Process the current `line' (from a selection list received
            # from the server): Extract the "object number" and "object
            # name" and insert this pair into `obj_table', where "object
            # number" is the key and "object name" is the data item.
        local
            objname, objnumber: STRING
            work_string: STRING
        do
            work_string = sub ("\)", "", line)
            objnumber = sub (" .*", "", work_string)
            objname = sub ("^[^ ]*  *", "", work_string)
            # Strip off trailing spaces:
            objname = sub ("[ %T]*$", "", objname)
            obj_table.force (objnumber, objname)
            debug ("sc")
                print ("Stored: " + obj_table @ objname + " (" +
                    objname + ")%N")
            end
        end

    process_2_column_selection_line (obj_table: HASH_TABLE [STRING, STRING];
        line: STRING)
            # Process the current `line' (from a selection list received
            # from the server) as a line from a two-column selection list:
            # For each column: extract the "object number" and "object
            # name" and insert this pair into `obj_table', where "object
            # number" is the key and "object name" is the data item.
        local
            item1, item2: STRING
        do
            if
                match ("^([0-9]+\).*)[ %T]+([0-9]+\).*)[ %T]*", line)
            then
                item1 = last_regular_expression.captured_substring (1)
                item2 = last_regular_expression.captured_substring (2)
                process_selection_line (obj_table, item1)
                process_selection_line (obj_table, item2)
            else
                io.error.print ("Defect: object selection match failed to " +
                    "match line:%N" + line +
                    "%NPlease report this bug bug to the MAS developers.%N")
                fatal_error = true
                error = true
            end
        end

    fuzzy_matches (phrase: STRING; attempted_target_set: ARRAY [STRING];
        char_compare_limit: INTEGER): ARRAY [STRING]
            # "fuzzy" matches, if any, of `phrase' with `attempted_target_set'
            # If no match is found, result is empty.
        require
            existence: phrase /= Void and then attempted_target_set /= Void
            sane_limit: char_compare_limit > 0 and then
                char_compare_limit < SANE_CHAR_LIMIT
        local
            new_limit: INTEGER
            previous_matches: ARRAY [STRING]
        do
            create result.make_empty
            # (Put matches into result.)
            attempted_target_set.do_all(agent (s, p: STRING;
                    limit: INTEGER; res: ARRAY [STRING])
                do
                    if s.same_characters(p, 1, limit, 1) then
                        debug ("process")
                            log_error("[fuzz] found match: " + s + "%N")
                        end
                        res.force(s, res.count + 1)
                    end
                end
                (?, phrase, char_compare_limit, result))
            if result.count > 1 then
                previous_matches = result
                new_limit = char_compare_limit + 1
                if new_limit < SANE_CHAR_LIMIT then
                    # Recursively attempt to narrow the matches
                    result = fuzzy_matches(phrase, result, new_limit)
                    if result.count = 0 then
                        # (2+ matches are better than 0.)
                        result = previous_matches
                    end
                end
            end
        ensure
            result_exists: result /= Void
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

  non_shared_pattern: STRING = ".*List of valid non.shared objects:.*"

  # Pattern indicating that the user response indicates a
  # "shared" object
  shared_pattern: STRING = "shared *"

  # String used to label a user response as specifying a
  # "shared" object
  shared_string: STRING = "shared "

  # Regular-expression patterns used to determine if
  # an "object-selection-list" is being presented to the user
  attr_accessor :select_patterns    # ARRAY [STRING]

  # Unshared objects listed in the last "object-selection-list"
  attr_accessor :objects            # HASH_TABLE [STRING, STRING]

  # Shared objects listed in the last "object-selection-list"
  attr_accessor :shared_objects     # HASH_TABLE [STRING, STRING]

  # Pattern indicating that the server has sent a "selection list"
  selection_list_pattern: STRING = "^[1-9][0-9]*\)"

  # Pattern indicating that the server has sent a 2-column
  # "selection list"
  two_column_selection_list_pattern: STRING =
    "^[1-9][0-9]*\).*[ %T][1-9][0-9]*\)"

  SANE_CHAR_LIMIT = 100

=begin
  invariant

    object_comparison: objects.object_comparison and
        shared_objects.object_comparison
    regular_expression_not_anchored: last_regular_expression /= Void implies
        not last_regular_expression.is_anchored
=end

end

# Command-line user interface functionality
# Note!!!!:
# !!!!This class redefines print from GENERAL.  Classes that inherit from
# this class and one or more other classes will need to undefine
# the version of print inherited from the other classes.!!!!
module CommandLineUtilities

=begin
  ANY
    redefine
      print
    end
=end

=begin
  GeneralUtilities
    export
      {NONE} all
    undefine
      print
    end
=end

=begin
  EXCEPTIONS
    export
      {NONE} all
    undefine
      print
    end
=end

  protected

  # User-selected character
  def character_selection(msg)
      current_lines_read = 0
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

=begin
  integer_selection (msg: STRING): INTEGER
      # User-selected integer value
    do
      current_lines_read := 0
      if msg /= Void and not msg.is_empty then
        print_list (<<"Enter an integer value for ", msg, " ", eom>>)
      end
      read_integer
      result := last_integer
    end

  real_selection (msg: STRING): DOUBLE
      # User-selected real value
    do
      current_lines_read := 0
      if msg /= Void and not msg.is_empty then
        print_list (<<"Enter a real value for ", msg, " ", eom>>)
      end
      read_real
      result := last_double
    end

  string_selection (msg: STRING): STRING
      # User-selected real value
    do
      current_lines_read := 0
      if msg /= Void and not msg.is_empty then
        print_list (<<msg, " ", eom>>)
      end
      read_line
      result := last_string.twin
    ensure
      result_exists: result /= Void
    end

  list_selection (l: LIST [STRING]; general_msg: STRING): INTEGER
      # User's selection from an element of `l'
    do
      current_lines_read := 0
      print_list (<<general_msg, "\n">>)
      from
      until
        result /= 0
      loop
        print_names_in_1_column (l, 1)
        print (eom)
        read_integer
        if
          last_integer < 1 or
            last_integer > l.count
        then
          print_list (<<"Selection must be between 1 and ",
                l.count, "\n">>)
        else
          inspect
            character_selection (concatenation (
              <<"Select ", l @ last_integer, "? (y/n) ">>))
          when 'y', 'Y' then
            result := last_integer
          else
          end
        end
      end
    ensure
      in_range: result >= 1 and result <= l.count
    end

  backoutable_selection (l: LIST [STRING]; msg: STRING;
        exit_value: INTEGER): INTEGER
      # User's selection from an element of `l', which can be
      # backed out of by entering 0 - `exit_value' is the value to
      # return to indicate the the user has backed out.
    local
      finished: BOOLEAN
    do
      current_lines_read := 0
      from
        if l.count = 0 then
          finished := true
          result := exit_value
          print ("There are no items to edit.\n")
        end
      until
        finished
      loop
        print_list (<<msg, ":\n">>)
        print_names_in_1_column (l, 1)
        print ("(0 to end) ")
        print (eom)
        read_integer
        if
          last_integer < 0 or
            last_integer > l.count
        then
          print_list (<<"Selection must be between 0 and ",
                l.count, "\n">>)
        elseif last_integer = 0 then
          finished := true
          result := exit_value
        else
          check
            valid_index: last_integer > 0 and
                  last_integer <= l.count
          end
          finished := true
          result := last_integer
        end
      end
    end

  multilist_selection (lists: ARRAY [PAIR [LIST [STRING], STRING]];
        general_msg: STRING): INTEGER
      # User's selection of one element from one of the `lists'.
      # Display all lists in `lists' that are not empty and return
      # the relative position of the selected item.  For example,
      # if the first list has a count of 5 and the 2nd item in the
      # 2nd list is selected, return a value of 7 (5 + 2).
    local
      i, startnum, columns, max_label_size: INTEGER
    do
      current_lines_read := 0
      # Maximum size of an item label, e.g.: "11) "
      max_label_size := 4
      print (general_msg)
      from
      until
        result /= 0
      loop
        from
          i := 1; startnum := 1
        until
          i = lists.count + 1
        loop
          if lists.item (i).left.count > 0 then
            if
              longest_string (lists.item (i).left) +
              max_label_size > Maximum_screen_width / 2
            then
              columns := 1
            else
              columns := 2
            end
            print (lists.item (i).right)
            print_names_in_n_columns (lists.item (i).left, columns,
              startnum)
          end
          startnum := startnum + lists.item (i).left.count
          i := i + 1
        end
        check
          # startnum = the sum of the count of all `left' elements
          # of lists
        end
        print (eom)
        read_integer
        if
          last_integer < 1 or
            last_integer >= startnum
        then
          print_list (<<"Selection must be between 1 and ",
                startnum - 1, "\n">>)
        else
          result := last_integer
        end
      end
      check
        result < startnum
      end
    end
=end

  # Input/output media to which all input will be sent and
  # from which output will be received, respectively
  attr_accessor :input_device, :output_device # IO (or File, TCPSocket or ...?)

##### Input

=begin
  read_integer
      # Input an integer (as a sequence of digits terminated with
      # a newline) and place the result in `last_integer'.  If
      # any non-digits are included in the input or the input
      # is empty, last_integer is set to 0.
    do
      read_input_line
      if input_device.last_string.is_integer then
        last_integer := input_device.last_string.to_integer
      else
        last_integer := 0
      end
    end

  read_real
      # Input a real (as a sequence of characters terminated with
      # a newline) and place the result in `last_double'.  If the
      # entered characters do not make up a real value, last_double is
      # set to 0.
    do
      read_input_line
      if input_device.last_string.is_real then
        last_double := input_device.last_string.to_real
      else
        last_double := 0
      end
    end
=end

  # Input a string and place it in `last_string'.
  def read_line
    read_input_line
    last_string = input_device.last_string
  end

  # If `Line_limit' is less than 0 or `current_lines_read' <
  # `Line_limit', read the next line from `input_device'.
  # If `Line_limit' is greater than 0 and `current_lines_read' >=
  # `Line_limit', `current_lines_read' is set to 0 and an
  # exception is thrown.
  def read_input_line
    if Line_limit < 0 || current_lines_read < Line_limit then
      input_device.read_line
    else
      current_lines_read = 0
      raise (Line_limit_reached)
    end
    current_lines_read = current_lines_read + 1
  end

##### Miscellaneous

=begin
  print_message (msg: STRING)
      # Print `msg' to standard out, appending a newline.
    do
      print_list (<<msg, "\n">>)
    end

  do_choice (descr: STRING; choices: LIST [PAIR [STRING, BOOLEAN]];
        allowed_selections: INTEGER)
      # Implementation, needed by some children, of procedure for
      # obtaining a desired list of selections from the user -
      # resulting in the right member of each pair in `choices'
      # set to true and the right member of all other pairs
      # set to false.
    local
      finished, choice_made: BOOLEAN
      slimit: INTEGER
      names: ARRAYED_LIST [STRING]
    do
      from
        slimit := allowed_selections
        print_list (<<descr, "\n(Up to ",
              allowed_selections, " choices)\n">>)
        from
          create names.make (choices.count)
          choices.start
        until
          choices.exhausted
        loop
          names.extend (choices.item.left)
          choices.forth
        end
      until
        slimit = 0 or finished
      loop
        from
          choice_made := false
        until
          choice_made
        loop
          print ("Select an item (0 to end):\n")
          print_names_in_1_column (names, 1); print (eom)
          read_integer
          if
            last_integer <= -1 or
            last_integer > choices.count
          then
            print_list (<<"Selection must be between 0 and ",
                  choices.count, "\n">>)
          elseif last_integer = 0 then
            finished := true
            choice_made := true
          else
            print_list (
                <<"Added %"", names @ last_integer,
                "%"\n">>)
            choices.i_th (last_integer).set_right (true)
            choice_made := true
          end
        end
        slimit := slimit - 1
      end
    end
=end

  protected

  ##### Implementation

  attr_accessor :last_integer   # INTEGER
      # Last integer input with `read_integer'

  attr_accessor :last_double    # DOUBLE
      # Last real input with `read_real'

  attr_accessor :last_string    # STRING
      # Last string input with `read_line'

  # Maximum number of lines that will be read - until
  # current_lines_read is reset to 0 - before a
  # `Line_limit_reached' exception is thrown - A value
  # less than 0 signifies no limit.
  def Line_limit
    # Redefine to -1 for no line limit.
    result = 1000
  end

  # Name of line-limit-reached exception
  Line_limit_reached = "Input line limit reached"

  # Current number of lines read in one input attempt
  attr_accessor :current_lines_read   # INTEGER

  # Redefinition of output method inherited from GENERAL to
  # send output to output_device
  def print(o)
    if o != nil then
      output_device.print(o)
    end
  end

=begin
  eom: STRING
      # End-of-message string - redefine if needed
    once
      result := ""
    end

  input_not_readable_error_message: STRING
    do
      result := "Input"
      if
        input_device /= Void and then
        input_device.name /= Void and then
        not input_device.name.is_empty
      then
        result := result + " " + input_device.name
      end
      result := result + " is not readable."
    end
=end

  def invariant
    implies(Line_limit >= 0, current_lines_read <= Line_limit)
  end

end

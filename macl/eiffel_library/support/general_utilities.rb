# General utility routines
module GeneralUtilities

  public

  ##### String manipulation

=begin
  concatenation (a: ARRAY [ANY]): STRING
      # A string containing a concatenation of all elements of `a'
    require
      not_void: a /= Void
    local
      i: INTEGER
    do
      create Result.make (0)
      from
        i := a.lower
      until
        i = a.upper + 1
      loop
        if a @ i /= Void then
          Result.append ((a @ i).out)
        end
        i := i + 1
      end
    ensure
      not_void: Result /= Void
    end

  list_concatenation (l: LINEAR [ANY]; suffix: STRING): STRING
      # A string containing a concatenation of all elements of `l',
      # with `suffix', if it is not empty, appended to each element
    require
      not_void: l /= Void
    local
      s: STRING
    do
      from
        Result := ""
        s := ""
        if suffix /= Void and then not suffix.is_empty then
          s := suffix
        end
        l.start
      until
        l.exhausted
      loop
        if l.item /= Void then
          Result.append (l.item.out + s)
        end
        l.forth
      end
    ensure
      not_void: Result /= Void
      empty_if_empty: l.is_empty implies Result.is_empty
    end

  field_concatenation (l: LINEAR [ANY]; separator: STRING): STRING
      # A string containing a concatenation of all elements of `l'
      # interpreted as fields - that is, with `separator' appended
      # to the first to next-to-last elements of `l'
    require
      not_void: l /= Void and separator /= Void
    local
      s: STRING
    do
      from
        Result := ""
        s := separator
        l.start
        if not l.exhausted then
          Result := Result + l.item.out
          l.forth
        end
      until
        l.exhausted
      loop
        Result := Result + s
        if l.item /= Void then
          Result := Result + l.item.out
        end
        l.forth
      end
    ensure
      not_void: Result /= Void
      empty_if_empty: l.is_empty implies Result.is_empty
    end

  replace_token_all (target, token, new_value: STRING;
    start_delimiter, end_delimiter: CHARACTER)
      # Replace in `target' all occurrences of
      # `start_delimiter' + `token' + `end_delimiter'
      # with `new_value'.
    require
      args_exist: target /= Void and token /= Void and new_value /= Void
    local
      replacement: STRING
    do
      replacement := token.twin
      replacement.prepend_character (start_delimiter)
      replacement.append_character (end_delimiter)
      target.replace_substring_all (replacement, new_value)
    end

  replace_tokens (target: STRING; tokens: ARRAY [STRING]; values:
    ARRAY [STRING]; token_start, token_end: CHARACTER)
      # Replace all occurrences of `tokens' in `target' with
      # the respective specified `values', where each token
      # begins with `token_start' and ends with `token_end'.
    require
      args_exists: target /= Void and tokens /= Void and values /= Void
      same_number_of_tokens_and_values: tokens.count = values.count
      same_index_settings: tokens.lower = values.lower and
        tokens.upper = values.upper
    local
      i: INTEGER
    do
      from
        i := tokens.lower
      until
        i = tokens.upper + 1
      loop
        replace_token_all (target, tokens @ i, values @ i,
          token_start, token_end)
        i := i + 1
      end
    end

  merged (l: LIST [STRING]; separator: STRING): STRING
      # Concatenation of `l' into a string whose elements are
      # separated with `separator'
    require
      args_exist: l /= Void and separator /= Void
    do
      if not l.is_empty then
        from
          l.start
          Result := l.item.twin
          l.forth
        until
          l.exhausted
        loop
          Result.append (separator + l.item)
          l.forth
        end
      else
        Result := ""
      end
    ensure
      exists: Result /= Void
      empty_if_l_empty: l.is_empty implies Result.is_empty
      no_separator_at_end: not Result.is_empty implies
        Result.item (Result.count) = l.last.item (l.last.count)
    end

  split_in_two (s: STRING; separator: CHARACTER): CHAIN [STRING]
      # The result of splitting `s' in two at the point of the
      # first occurrence in `s' of `separator', where the component
      # in `s' to the left of `separator' is placed in Result @ 1
      # and the component in `s' to the right of `separator' is
      # placed in Result @ 2
    local
      i: INTEGER
      l: LINKED_LIST [STRING]
    do
      create l.make
      if s.has (separator) then
        i := s.index_of (separator, 1)
        l.extend (s.substring (1, i - 1))
        l.extend (s.substring (i + 1, s.count))
      else
        l.extend (s.twin)
      end
      Result := l
    ensure
      result_exists: Result /= Void
      no_more_than_2: Result.count <= 2
      no_less_than_1: Result.count >= 1
      two_if_s_has_separator: s.has (separator) = (Result.count = 2)
      one_if_not_s_has_separator: not s.has (separator) =
        (Result.count = 1)
    end

  n_spaces (n: INTEGER): STRING
      # `n' spaces - Empty string if n < 0
    do
      if n < 0 then
        create Result.make (0)
      else
        create Result.make (n)
      end
      Result.fill_blank
    end

  longest_string (l: LIST [STRING]): INTEGER
      # Longest string in `l'
    require
      l_exists: l /= Void
    do
      Result := 0
      from
        l.start
      until
        l.exhausted
      loop
        if l.item.count > Result then
          Result := l.item.count
        end
        l.forth
      end
    end
=end

  ##### Text formatting

=begin
  print_list (l: ARRAY [ANY])
      # Print all members of `l'.
    require
      not_void: l /= Void
    local
      i: INTEGER
    do
      from
        i := l.lower
      until
        i = l.upper + 1
      loop
        if l @ i /= Void then
          print (l @ i)
        end
        i := i + 1
      end
    end

  print_actual_list (l: LIST [ANY]; newlines: BOOLEAN)
      # Print all members of `l'.
      # If `newlines' a new line is printed after each element.
    require
      not_void: l /= Void
    do
      from
        l.start
      until
        l.exhausted
      loop
        if l.item /= Void then
          print (l.item)
          if newlines then print ("%N") end
        end
        l.forth
      end
    end

  print_row (names: LIST [STRING]; row, rows, cols, namecount,
      column_pivot, row_width, first_row_label: INTEGER)
    local
      column, i, item_label: INTEGER
      math: expanded DOUBLE_MATH
    do
      from column := 1 until
        column = cols or
        (row = rows and column_pivot > 0 and column > column_pivot)
      loop
        if column_pivot > 0 and column - 1 > column_pivot then
          i := row + rows * column_pivot +
            (rows - 1) * (column - 1 - column_pivot)
        else
          i := row + rows * (column - 1)
        end
        if i <= namecount then
          item_label := i + first_row_label - 1
          print_list (<<item_label, ") ", names @ i,
            n_spaces ((row_width / cols - (math.floor (math.log10 (
            item_label)) + cols - 1 +
            names.i_th(i).count)).ceiling)>>)
        end
        column := column + 1
      end
      if
        not (row = rows and column_pivot > 0 and column > column_pivot)
      then
        if column_pivot > 0 and column - 1 > column_pivot then
          i := row + rows * column_pivot +
            (rows - 1) * (column - 1 - column_pivot)
        else
          i := row + rows * (column - 1)
        end
        if i <= namecount then
          item_label := i + first_row_label - 1
          print_list (<<item_label, ") ", names @ i>>)
        end
      end
      print ("%N")
    end

  print_names_in_n_columns (names: LIST [STRING];
    cols, first_number: INTEGER)
      # Print each element of `names' as a numbered item
      # to the screen in `cols' columns.  Numbering is from
      # first_number to first_number + names.count - 1.
    local
      rows, row, end_index, namecount, col_pivot: INTEGER
    do
      namecount := names.count
      rows := (namecount + cols - 1) // cols
      col_pivot := namecount \\ cols
      end_index := rows * cols
      row := 1
      from
      until
        row = rows + 1
      loop
        print_row (names, row, rows, cols, namecount, col_pivot,
          Maximum_screen_width, first_number)
        row := row + 1
      end
    end

  print_names_in_1_column (names: LIST [STRING]; first_number: INTEGER)
      # Print each element of `names' as a numbered item to the
      # screen in 1 column.  Numbering is from first_number to
      # first_number + names.count - 1.
    local
      i: INTEGER
    do
      from
        i := first_number
        names.start
      until
        names.exhausted
      loop
        print_list (<<i, ") ", names.item, "%N">>)
        names.forth
        i := i + 1
      end
      check
        i = first_number + names.count
      end
    end
=end

##### Time/date utilities

=begin
  now_date: DATE
      # A new object with the current date
    do
      create Result.make_now
    ensure
      exists: Result /= Void
    end

  now_date_time: DATE_TIME
      # A new object with the current date/time
    do
      create Result.make_now
    ensure
      exists: Result /= Void
    end

  now_time: TIME
      # A new object with the current time
    do
      create Result.make_now
    ensure
      exists: Result /= Void
    end
=end

##### Logging

=begin
  log_error (msg: STRING)
      # Log `msg' as an error.
      # If `msg' is longer than `Maximum_message_length', only
      # the first `Maximum_message_length' characters of `msg'
      # will be logged.
    local
      s: STRING
    do
      if msg /= Void then
        s := msg
        if msg.count > Maximum_message_length then
          s := msg.substring (1, Maximum_message_length) + "%N"
        end
        io.error.put_string (s)
      end
    end
=end

  # Log `list' of error messages.  If any element of `list' is
  # longer than `Maximum_message_length', only the first
  # `Maximum_message_length' characters of that element will
  # be logged.
  def log_errors(list)
    #!!!!!![TBI]!!!!!!
  end

=begin
#!!!!!old:
  log_errors (list: ARRAY [ANY])
      # Log `list' of error messages.  If any element of `list' is
      # longer than `Maximum_message_length', only the first
      # `Maximum_message_length' characters of that element will
      # be logged.
    require
      not_void: list /= Void
    local
      i: INTEGER
    do
      from
        i := list.lower
      until
        i = list.upper + 1
      loop
        if list @ i /= Void then
          log_error ((list @ i).out)
        end
        i := i + 1
      end
    end

  log_error_list (list: LIST [ANY])
      # Log actual LIST of error messages.  If any element of `list' is
      # longer than `Maximum_message_length', only the first
      # `Maximum_message_length' characters of that element will
      # be logged.
    require
      not_void: list /= Void
    do
      list.do_all (agent log_error)
    end

  log_information (msg: STRING)
      # Log `msg' as (non-error) information.
    require
      not_void: msg /= Void
    do
      io.print (msg)
    end
=end

##### Miscellaneous

=begin
  microsleep (seconds, microseconds: INTEGER)
      # Sleep for the specified number of `seconds' and `microseconds'.
    require
      less_than_one_millions: microseconds < 1000000
    external
       "C"
    end

  deep_copy_list (target, source: LIST [ANY])
      # Do a deep copy from `source' to `target' - work-around
      # for apparent bug in LINKED_LIST's deep_copy.
    local
      temp: like target
    do
      temp := source.deep_twin
      target.copy (temp)
    end

  check_objects (a: ARRAY [ANY]; descriptions: ARRAY [STRING];
    ok: FUNCTION [ANY, TUPLE [ANY], BOOLEAN]; handler:
    PROCEDURE [ANY, TUPLE [LINEAR [STRING]]];
    proc_arg: ANY; info: ANY)
      # For each "i" in `a.lower' to `a.upper', if a @ i is not `ok',
      # insert descriptions @ i into a list and execute `handler'
      # on the list.  `proc_arg' is an additional, optional (can
      # be Void) argument to `handler' and `info' is an optional
      # error description to pass on to `handler'.
    require
      valid_args: a /= Void and descriptions /= Void and
        a.count = descriptions.count
      same_ranges: a.lower = descriptions.lower and
        a.upper = descriptions.upper
    local
      i: INTEGER
      invalid_items: LINKED_LIST [STRING]
    do
      from
        create invalid_items.make
        i := a.lower
      until
        i = a.upper + 1
      loop
        if not ok.item ([a @ i]) then
          invalid_items.extend (descriptions @ i)
        end
        i := i + 1
      end
      if not invalid_items.is_empty then
        handler.call ([invalid_items, proc_arg, info])
      end
    end

  is_not_void (o: ANY): BOOLEAN
      # Is `o' not Void?  (Candidate `ok' function for `check_objects')
    do
      Result := o /= Void
    end

  is_void (o: ANY): BOOLEAN
      # Is `o' Void?  (Candidate `ok' function for `check_objects')
    do
      Result := o = Void
    end

  no_elements_void (l: TRAVERSABLE [ANY]): BOOLEAN
      # Are all elements of `l' non-Void?
    do
      Result := l.for_all (agent is_not_void)
    end

  non_empty_string (s: STRING): BOOLEAN
      # Is `s' not empty?
    do
      Result := s /= Void and then not s.is_empty
    ensure
      Result = (s /= Void and then not s.is_empty)
    end

  string_boolean_pair (s: STRING; b: BOOLEAN): PAIR [STRING, BOOLEAN]
      # A PAIR with `s' as the left item and `b' as the right item
    do
      create Result.make (s, b)
    ensure
      result_exists: Result /= Void
      s_left_b_right: Result.left = s and Result.right = b
    end
=end

##### List manipulation

=begin
  append_string_boolean_pair (l: SEQUENCE [PAIR [STRING, BOOLEAN]];
    s: STRING; b: BOOLEAN)
      # Wrap `s' and `b' into a PAIR and append the pair to `l'.
    require
      l_exists: l /= Void
    do
      l.extend (string_boolean_pair (s, b))
    end
=end

##### Constants

=begin
  Maximum_message_length: INTEGER
      # Maximum length of messages to be logged
    once
      Result := 1000
    end

  Maximum_screen_width: INTEGER
      # Maximum width for the text-based display screen
    once
      Result := 78
    end
=end

end

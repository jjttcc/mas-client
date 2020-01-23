require 'ruby_contracts'
require 'date'

# General utility routines
module GeneralUtilities
  include Contracts::DSL

  public

  ##### String manipulation

  # A string containing a concatenation of all elements of `a'
  pre  :not_void do |a| a != nil end
  post :not_void do |result| result != nil end
  def concatenation(a)
    a.join
  end

  # A string containing a concatenation of all elements of `l',
  # with `suffix', if it is not empty, appended to each element
  pre  :not_void do |l| l != nil end
  post :not_void do |result| result != nil end
  post :empty_if_empty do |result, l|
    implies l.empty?, result.empty? end
  def list_concatenation(l, suffix)
    l.join(suffix) + suffix.to_s
  end

  # A string containing a concatenation of all elements of `l'
  # interpreted as fields - that is, with `separator' appended
  # to the first to next-to-last elements of `l'
  pre  :not_void do |l, separator| l != nil && separator != nil end
  post :not_void do |result| result != nil end
  post :empty_if_empty do |result, l| l.empty? implies result.empty? end
  def field_concatenation(l, separator)
    l.join(suffix)
  end

  # Replace in `target' all occurrences of
  # `start_delimiter' + `token' + `end_delimiter'
  # with `new_value'.
  pre  :args_exist do |target, token, new_value|
    target != nil && token != nil && new_value != nil end
  def replace_token_all(target, token, new_value,
                        start_delimiter, end_delimiter)
    replacement = token.clone
    replacement.prepend_character(start_delimiter)
    replacement.append_character(end_delimiter)
    target.replace_substring_all(replacement, new_value)
  end

  # Replace all occurrences of `tokens' in `target' with
  # the respective specified `values', where each token
  # begins with `token_start' and ends with `token_end'.
  pre  :args_exists do |target, tokens, values|
    target != nil && tokens != nil && values != nil end
  pre  :same_number_of_tokens_and_values do |target, tokens|
    tokens.count == values.count end
  def replace_tokens(target, tokens, values, token_start, token_end)
    (0..tokens.count - 1).each do |i|
      replace_token_all(target, tokens[i], values[i], token_start, token_end)
    end
  end

  # Concatenation of `l' into a string whose elements are
  # separated with `separator'
  pre  :args_exist do |l, separator| l != nil && separator != nil end
  post :exists do |result| result != nil end
  post :empty_if_l_empty do |result, l| implies l.empty?, result.empty? end
  post :no_separator_at_end do |result, l| implies(! result.empty?,
         result[-1] == l.last.to_s[-1]) end
  def merged(l, separator)
    result = l.join(separator)
    result
  end

  # `n' spaces - Empty string if n <= 0
  def n_spaces(n)
    if n <= 0 then
      result = ""
    else
      result = " " * n
    end
    result
  end

  # Length of the longest string in `l'
  pre  :l_exists do |l| l != nil end
  def longest_string(l)
    result = 0
    l.each do |s|
      if s.length > result then
        result = s.length
      end
    end
    result
  end

  ##### Text formatting

  # Print all members of `l'.
  pre :not_void do |l| l != nil end
  def print_list(l)
    l.each do |e|
      print e
    end
  end

  # Print all members of `l'.
  # If `newlines' a new line is printed after each element.
  pre  :not_void do |l| l != nil end
  def print_actual_list(l, newlines)
    suffix = ""
    if newlines then suffix = "\n" end
    l.each do |e|
      if e != nil then
        print("#{e}#{suffix}")
      end
    end
  end

  # Print each element of `names' as a numbered item to the
  # screen in 1 column.  Numbering is from first_number to
  # first_number + names.count - 1.
  def print_names_in_1_column(names, first_number)
    n = first_number
    names.each do |name|
      print("#{n}) #{name}\n")
      n += 1
    end
  end

  ##### Time/date utilities

  # A new object with the current date
  post :exists do |result| result != nil end
  def now_date
    DateTime.now.to_date
  end

  # A new object with the current date/time
  post :not_void do |result| result != nil end
  def now_date_time
    DateTime.now
  end

    # A new object with the current time
  post :not_void do |result| result != nil end
  def now_time
    Time.now
  end

  ##### Logging

  # Log `msg' as an error.
  # If `msg' is longer than `Maximum_message_length', only
  # the first `Maximum_message_length' characters of `msg'
  # will be logged.
  def log_error(msg)
    if msg != nil then
      s = msg
      if msg.length > Maximum_message_length then
        s = msg[0, Maximum_message_length-1] + "\n"
      end
      $stderr.print(s)
    end
  end

  # Log `list' of error messages.  If any element of `list' is
  # longer than `Maximum_message_length', only the first
  # `Maximum_message_length' characters of that element will
  # be logged.
  def log_errors(list)
    list.each do |e|
      if e != nil then
        log_error(e.to_s)
      end
    end
  end

  alias_method :log_error_list, :log_errors

  # Log `msg' as (non-error) information.
  pre  :not_void do |msg| msg != nil end
  def log_information(msg)
    $stdout.print(msg)
  end

  ##### Constants

  # Maximum length of messages to be logged
  Maximum_message_length = 1000

  # Maximum width for the text-based display screen
  Maximum_screen_width = 78

end

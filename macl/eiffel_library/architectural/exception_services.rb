require 'ruby_contracts'
require 'cleanup_services'
require 'exception_status'

# Facilities for exception handling and program termination -
# intended to be used via inheritance
module ExceptionServices
  include Contracts::DSL, CleanupServices

  privatize_public_methods(CleanupServices)

  public

  ##### Access

  # Error status for exit
  def error_exit_status
    1
  end

  # Should `termination_cleanup' NOT be called by `exit'?
  attr_accessor :no_cleanup   # BOOLEAN

  # Status of last exception that occurred, if any
  def last_exception_status
    if @last_exception_status.nil? then
       @last_exception_status = ExceptionStatus.new
    end
    @last_exception_status
  end

  ##### Status report

  # Should `error_information' include detailed exception information?
  # (Defaults to true.)
  def verbose_reporting
    result = ! not_verbose_reporting
  end

  ##### Status setting

  # Set `verbose_reporting' to true.
  post :verbose do verbose_reporting end
  def set_verbose_reporting_on
    self.not_verbose_reporting = false
  end

  # Set `verbose_reporting' to false.
  post :not_verbose do ! verbose_reporting end
  def set_verbose_reporting_off
    self.not_verbose_reporting = true
  end

##### Basic operations

=begin
#!!!!!![convert or remove:]
  handle_exception (routine_description: STRING)
    local
      error_msg: STRING
      fatal: BOOLEAN
    do
      # An exception may have caused a lock to have been left open -
      # ensure that clean-up occurs to remove the lock:
      no_cleanup := false
      if assertion_violation then
        handle_assertion_violation
      elseif exception /= Signal_exception then
        if is_developer_exception then
          error_msg := ":%N" + developer_exception_name + "%N"
          fatal := last_exception_status.fatal
        else
          error_msg := "%N"
          fatal := last_exception_status.fatal or
            fatal_exception (exception)
        end
        log_errors (<<"%NError encountered - ", routine_description,
          error_msg, error_information ("Exception", false)>>)
      elseif
        signal = Sigterm or signal = Sigabrt or signal = Sigquit
      then
        log_errors (<<"%NCaught kill signal in ", routine_description,
          ":%N", signal_meaning (signal), " (", signal, ")",
          "%NDetails: ", error_information ("Exception ", true),
          "%Nexiting ...%N">>)
        fatal := true
      else
        log_errors (<<"%NCaught signal in ", routine_description,
          ":%N", signal_meaning (signal), " (", signal, ")",
          "%NDetails: ", error_information ("Exception ", true)>>)
        fatal := last_exception_status.fatal
        if fatal then
          log_error(" - exiting ...%N")
        else
          log_error(" - continuing ...%N")
        end
      end
      if fatal then
        exit (Error_exit_status)
      else
        last_exception_status.set_description ("")
      end
    end

  exit (status: INTEGER)
      # Exit the application with the specified status.  If `no_cleanup'
      # is false, call `termination_cleanup'.
    do
      if verbose_reporting then
        if status /= 0 then
          log_information ("Aborting the " +
            application_name + ".%N")
        else
          log_information ("Terminating the " +
            application_name + ".%N")
        end
      end
      if ! no_cleanup then
        debug ("persist")
          log_information ("Cleaning up ...%N")
        end
        termination_cleanup
        debug ("persist")
          log_information ("Finished cleaning up.%N")
        end
      end
      die (status)
      # Sometimes die does not work - ensure program termination:
      end_program (status)
    rescue
      # Make sure that program terminates when an exception occurs.
      die (status)
      end_program (status)
    end

  end_program (i: INTEGER)
      # Replacement for `die', since it appears to sometimes fail to
      # exit
    external
      "C"
    end

  fatal_exception (e: INTEGER): BOOLEAN
      # Is `e' an exception that is considered fatal?
    do
      result = exception_list.has (e) and ! (e = External_exception
        or e = Floating_point_exception or e = Routine_failure or
        e = Io_exception)
    end

  error_information (errname: STRING; stack_trace: BOOLEAN): STRING
      # Information about the current exception, with a stack
      # trace if `stack_trace'
    local
      errtag: STRING
    do
      if errname /= Void then
        errtag := errname
      else
        errtag := DEFAULT_ERRNAME
      end
      check
        errtag_exists: errtag /= Void
      end
      if exception = Void_call_target then
        # Feature call on void target is a special case that can
        # cause problems (specifically, OS signal when calling
        # class_name) - so handle it separately.
        result = errtag + " occurred: " +
          meaning (exception)
        if verbose_reporting then
          result = result + "%N[Exception trace:%N" +
          exception_trace + "]%N"
        end
      else
        result = errtag + " occurred " +
          exception_routine_string + tag_string + class_name_string +
          exception_meaning_string (errname) + "%N"
        if verbose_reporting then
          if
            recipient_name /= Void and
            original_recipient_name /= Void and not
            recipient_name.is_equal (original_recipient_name)
          then
            result = result + "(Original routine where the violat%
              %ion occurred: " + original_recipient_name + ".)%N"
          end
          if
            tag_name /= Void and original_tag_name /= Void and
            ! tag_name.is_equal (original_tag_name)
          then
            result = result + "(Original tag name: " +
              original_tag_name + ".)%N"
          end
          if
            class_name /= Void and original_class_name /= Void and
            ! class_name.is_equal (original_class_name)
          then
            result = result + "(Original class name: " +
              original_class_name + ".)%N"
          end
          if stack_trace then
            result = result + "%N[Exception trace:%N" +
              exception_trace + "]%N"
          end
        end
      end
      if ! last_exception_status.description.is_empty then
        if
          result != nil && ! result.empty? &&
          exception_list.has(exception)
        then
          result = last_exception_status.description +
            " - " + result
        else
          result = last_exception_status.description + "%N"
        end
      end
    end
=end

  private

  ##### Implementation - Hook routines

  # The name of the application to be used for error reporting
  def application_name
    "server"
  end

  ##### Implementation

=begin
#!!!!!![convert or remove:]
  exception_routine_string: STRING
    do
      result = ""
      if verbose_reporting then
        result = recipient_name
        if result != nil && ! result.empty? then
          result = "in routine `" + result + "' "
        else
          result = ""
        end
      end
    ensure
      result_exists: result != nil
    end

  tag_string: STRING
    local
      tgname: STRING
    do
      tgname := ""
      if tag_name /= Void then
        tgname := tag_name
      end
      if ! tgname.is_empty then
        result = ":%N%"" + tgname + "%"%N"
      else
        result = ""
      end
    ensure
    result_exists: result != nil
    end

  class_name_string: STRING
    do
      result = ""
      if verbose_reporting then
        result = class_name
        if result != nil && ! result.empty? then
          result = "from class %"" + result + "%".%N"
        else
          result = ""
        end
      end
    ensure
      result_exists: result != nil
    end

  exception_meaning_string (errname: STRING): STRING
    do
      result = ""
      if verbose_reporting then
        result = meaning (exception)
        if result != nil && ! result.empty? then
          if errname /= Void and ! errname.is_empty then
            result = "Type of " + errname + ": " + result
          else
            result = "(" + result + ")"
          end
        else
          result = ""
        end
      end
    ensure
      result_exists: result != nil
    end

  handle_assertion_violation
    do
      log_error (error_information (ASSERT_STRING, true))
      exit (Error_exit_status)
    end

  exception_list: ARRAY [INTEGER]
      # List of all known exception types
    once
      result = [Void_call_target, No_more_memory, Precondition,
        Postcondition, Floating_point_exception, Class_invariant,
        Check_instruction, Routine_failure, Incorrect_inspect_value,
        Loop_variant, Loop_invariant, Signal_exception,
        Rescue_exception, External_exception,
        Void_assigned_to_expanded, Io_exception,
        Operating_system_exception, Retrieve_exception,
        Developer_exception, Runtime_io_exception, Com_exception]
    end
=end

  ##### Implementation

  # Should `error_information' NOT include detailed
  # exception information?  (Allows defaulting to
  # `verbose_reporting'.)
  attr_accessor :not_verbose_reporting    # BOOLEAN

  ##### Implementation - constants

  ASSERT_STRING = "Assertion violation"

  # Default `errname' for `error_information' if none supplied
  DEFAULT_ERRNAME = "Error"

  # verbose_not_verbose_are_opposites
  def invariant
    verbose_reporting = ! not_verbose_reporting
  end

end

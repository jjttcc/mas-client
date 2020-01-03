# Extra exception status information (in addition to
# what is available in class EXCEPTIONS)
class ExceptionStatus

creation

  make

private

##### Initialization

  make
    do
      create description.make (0)
    end

public

##### Access

  description: STRING
      # Description of the cause of the exception

##### Status report

  fatal: BOOLEAN
      # Is the error condition that caused the exception considered
      # fatal?

##### Status setting

  set_fatal (arg: BOOLEAN)
      # Set fatal to `arg'.
    do
      fatal := arg
    ensure
      fatal_set: fatal = arg
    end

  set_description (arg: STRING)
      # Set description to `arg'.
    require
      arg_not_void: arg /= Void
    do
      description := arg
    ensure
      description_set: description = arg and description /= Void
    end

invariant

  description_not_void: description /= Void

end

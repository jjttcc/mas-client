# Constants specifying the basic components of the MA server
# communication protocol
module MACommunicationProtocol
  include BasicCommunicationProtocol

  public

  ##### String constants

  # End of message specifier
  def eom
    ""
  end

  # End of transmission specifier - for command-line clients
  def eot
    ""
  end

  # Flag indicating that the client is a console
  CONSOLE_FLAG = 'C'

  # Flag (at beginning of a message) that indicates that
  # the message is compressed
  COMPRESSION_ON_FLAG = "<@z@>"

  # Sub-field separator for date fields contained in messages
  def message_date_field_separator
    deferred
  end

  # Sub-field separator for time fields contained in messages
  def message_time_field_separator
    deferred
  end

  def invariant
    # eom_size:
    eom.length == 1
  end

end

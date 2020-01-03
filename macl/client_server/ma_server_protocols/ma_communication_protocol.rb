# Constants specifying the basic components of the MA server
# communication protocol
class MACommunicationProtocol <

  BasicCommunicationProtocol

public

##### String constants

  EOM = ""
      # End of message specifier

  EOT = ""
      # End of transmission specifier - for command-line clients

  CONSOLE_FLAG = 'C'
      # Flag indicating that the client is a console

  COMPRESSION_ON_FLAG = "<@z@>"
      # Flag (at beginning of a message) that indicates that
      # the message is compressed

  message_date_field_separator: STRING deferred end
      # Sub-field separator for date fields contained in messages

  message_time_field_separator: STRING deferred end
      # Sub-field separator for time fields contained in messages

invariant

  eom_size: EOM.count = 1

end

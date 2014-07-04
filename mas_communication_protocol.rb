# Constants: values used in the protocol between the Market-Analysis server
# and client
module MasCommunicationProtocol

  public  ### Client request IDs

  ALL_INDICATORS_REQUEST      = 11
  # Request for a list of all known indicators

  EVENT_DATA_REQUEST          = 9
  # Request for a list of market events - trading signals, sorted
  # by date, increasing

  EVENT_LIST_REQUEST          = 10
  # Request for a list of all event types valid for
  # a particular tradable and trading-period type

  INDICATOR_DATA_REQUEST      = 2
  # Request for data for a specified indicator for a
  # specified tradable

  INDICATOR_LIST_REQUEST      = 5
  # Request for a list of all available indicators for a
  # specified tradable

  LOGIN_REQUEST               = 6
  # Login request from GUI client - to be responded to
  # with a new session key and session state information

  LOGOUT_REQUEST              = 8
  # Logout request from GUI client

  TRADABLE_DATA_REQUEST       = 1
  # Request for data for a specified tradable

  TRADABLE_LIST_REQUEST       = 4
  # Request for a list of all available tradables

  SESSION_CHANGE_REQUEST      = 7
  # Request for a change in session settings

  TRADING_PERIOD_TYPE_REQUEST = 3
  # Request for a list of all valid trading period types for a
  # specified tradable

  public  ### Field separators

  MESSAGE_DATE_FIELD_SEPARATOR = ""

  MESSAGE_TIME_FIELD_SEPARATOR = ""

  public  ### Server response IDs

  ERROR               = 101
  # Response indicating that there was a problem receiving or
  # parsing the client request

  INVALID_PERIOD_TYPE = 105
  # Response indicating that the server requested data for
  # a period type that is not in the database

  INVALID_SYMBOL      = 103
  # Response indicating that the server requested data for
  # a symbol that is not in the database

  OK                  = 102
  # Response indicating that no errors occurred

  WARNING             = 104
  # Response indicating that a non-fatal error occurred

  public  ### Server response strings

  NO_OPEN_SESSION_STATE = "no_open"
  # Specification that there is no open field in the tradable data

  OPEN_INTEREST_FLAG    = "oi"
  # Specification that there is an open-interest field in
  # the tradable data

  public  ### String constants

  COMPRESSION_ON_FLAG = "<@z@>"
  # Flag (at beginning of a message) that indicates that
  # the message is compressed
  # (from MA_COMMUNICATION_PROTOCOL)

  CONSOLE_FLAG        = 'C'
  # Flag indicating that the client is a console
  # (from MA_COMMUNICATION_PROTOCOL)

  EOM                 = "\a"
  # End of message specifier
  # (from MA_COMMUNICATION_PROTOCOL)

  EOT                 = "\x04"  # (Control-D)
  # End of transmission specifier - for command-line clients
  # (from MA_COMMUNICATION_PROTOCOL)

  MESSAGE_COMPONENT_SEPARATOR = "\t"
  # Character used to separate top-level message components
  # (from BASIC_COMMUNICATION_PROTOCOL)

  MESSAGE_RECORD_SEPARATOR    = "\n"
  # Character used to separate "records" or "lines" within
  # a message component
  # (from BASIC_COMMUNICATION_PROTOCOL)

  public  ### Subtokens

  END_DATE   = "end_date"
  # Token specifying session setting for an end date

  START_DATE = "start_date"
  # Token specifying session setting for a start date

  public  ### Miscellaneous

  # "Dummy" session key to be used before obtaining a real key
  DUMMY_SESSION_KEY = 0

  NULL_FIELD        = ''    # An empty field

  NOW               = 'now' # Current date/time

  MSG_ID_IDX        = 0 # Expected location of msgID - in server message

  # (alias - for clarification/self-documentation)
  MSG_STATUS_IDX    = MSG_ID_IDX

  SESSION_KEY_IDX   = 1 # Expected location of session key - in server message

  DATA_IDX          = 1 # Expected location, in server message, of result data

end

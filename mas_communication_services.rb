require 'ruby_contracts'
require_relative 'mas_communication_protocol'
require_relative 'time_period_type_constants'

# Services/tools for communication with the Market-Analysis server
module MasCommunicationServices
  include MasCommunicationProtocol, TimePeriodTypeConstants
  include Contracts::DSL

  public

  attr_reader :session_key, :symbols

  public

  # Request all available tradable symbols from the server and initialize the
  # 'symbols' attribute with this list.
  #type :in => String, :out => String
  pre "session_key valid" do session_key != nil and session_key.length > 0 end
  def request_symbols
    sym_request = constructed_message([TRADABLE_LIST_REQUEST, session_key,
                                  NULL_FIELD])
    begin_communication
    send(sym_request)
    receive_response
    end_communication
    process_response(last_response)
    if response_ok?
      puts "Everything is OK!"
    else
      puts "Everything is NOT OK!!!!!"
      # !!!Reminder: Handle the error...
    end
    @symbols = symbols_from_response
  end

  protected

  attr_reader :last_response_components, :last_response

  protected ## Hook methods

  # Send 'msg' to the server.
  type :in => String
  pre "msg not empty" do |msg| msg.length > 0 end
  pre "msg ends in EOM" do |msg| msg[-1] == EOM end
  def send(msg)
    raise "abstract method"
  end

  # Server's response from the last 'send'
  type @last_response => String
  post "last_response exists" do last_response.length > 0 end
  def receive_response
    raise "abstract method"
  end

  # Perform any actions needed initially, before any communication has
  # occured.
  def initialize_communication
  end

  # Perform any actions needed in preparation for a send/receive
  # communication.
  def begin_communication
  end

  # Perform any actions that need to follow a send/receive communication.
  def end_communication
  end

  protected ## Constructed client requests

  # Initial message to the server to start a session
  type :out => String
  post "not empty" do |result| result.length > 0 end
  post "result ends in EOM" do |result| result[-1] == EOM end
  def initial_message
    constructed_message([LOGIN_REQUEST, DUMMY_SESSION_KEY, START_DATE,
                         DAILY_LABEL, 'now'])
  end

  protected ## Protocol-related implementation tools

  # Process response 'r' (String) and initialize last_response_components
  # with the resulting array.
  def process_response(r)
    r.sub!(/#{EOM}$/, '')  # Strip off end-of-message character at end.
    @last_response_components = r.split(MESSAGE_COMPONENT_SEPARATOR)
  end

  # The session key, if any, from the last response (stored in
  # last_response_components)
  def key_from_response
    last_response_components[SESSION_KEY_IDX]
  end

  # List of tradable symbols - assuming the last request was a symbol request
  # and that it was successful.
  def symbols_from_response
    last_response_components[SYMBOL_LIST_IDX].split(MESSAGE_RECORD_SEPARATOR)
  end

  # Was a successful/OK status resported as part of the last response?
  def response_ok?
    Integer(last_response_components[MSG_STATUS_IDX]) == OK
  end

  protected ## Utilities

  # Message, from 'parts' (array of message components), to be sent to the
  # server, with field-separators and EOM added.
  def constructed_message(parts)
    parts.join(MESSAGE_COMPONENT_SEPARATOR) + EOM
  end

  private

  # Send the 'initial_message' to the server, obtain the response, and use
  # it to set the session_key.
  def initialize(*args)
    initialize_communication(*args)
    begin_communication
    send(initial_message)
    receive_response
    end_communication
    process_response(last_response)
    if response_ok?
      puts "Everything is OK!"
    else
      puts "Everything is NOT OK!!!!!"
      # !!!Reminder: Handle the error...
    end
    @session_key = key_from_response
  end

end

#### !!!!Delete this stuff when it's no longer needed for reference.
=begin
INITSTR = "6	0	start_date	daily	now - 9 months	start_date	hourly	now - 2 months	start_date	30-minute	now - 55 days	start_date	20-minute	now - 1 month	start_date	15-minute	now - 1 month	start_date	10-minute	now - 18 days	start_date	5-minute	now - 18 days	start_date	weekly	now - 4 years	start_date	monthly	now - 8 years	start_date	quarterly	now - 10 years	end_date	daily	now\a"
=end

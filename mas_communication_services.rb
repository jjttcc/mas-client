require 'ruby_contracts'
require 'abstract'
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
  #pre do |key| key != nil end
  pre do true end
  def request_symbols
    sym_request = constructed_message([TRADABLE_LIST_REQUEST, session_key,
                                  NULL_FIELD])
    send(sym_request)
    result = response_from_send
=begin
puts "sending '#{symreq}'"
    @socket = TCPSocket.new(host, port)
    @socket.write(symreq)
    @socket.close_write
    result = @socket.read
=end
    process_response(result)
    if response_ok?
      puts "Everything is OK!"
    else
      puts "Everything is NOT OK!!!!!"
      # !!!Handle the error...
    end
#puts "last_response_components: "
#p last_response_components
#puts "request_symbols got #{result}"
    @symbols = symbols_from_response
  end

  protected

  attr_reader :last_response_components

  protected ## Hook methods

  abstract_method :send, :response_from_send

  #def send; end
  # Server's response from the last 'send'
  #def response_from_send; end

  protected ## Constructed client requests

  # Initial message to the server to start a session
  type :out => String
  post "not empty" do |result| result.length > 0 end
  post "result ends in EOM" do |result| result[-1] == EOM end
  def initial_message
    constructed_message([LOGIN_REQUEST, DUMMY_SESSION_KEY, START_DATE,
                         DAILY_LABEL, 'now'])
  end

  type :in => String, :out => String
  pre  "not empty" do |key| key.length > 0 end
  post "not empty" do |result| result.length > 0 end
  post "result ends in EOM" do |result| result[-1] == EOM end
  def old____symbol_request(session_key)
    constructed_message([TRADABLE_LIST_REQUEST, session_key, NULL_FIELD])
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
    last_response_components[1]
  end

  # List of tradable symbols - assuming the last request was a symbol request
  # and that it was successful.
  def symbols_from_response
    last_response_components[1].split(MESSAGE_RECORD_SEPARATOR)
  end

  # Was a successful/OK status resported as part of the last response?
  def response_ok?
    Integer(last_response_components[0]) == OK
  end

  protected ## Utilities

  # Message, from 'parts' (array of message components), to be sent to the
  # server, with field-separators and EOM added.
  def constructed_message(parts)
puts "mcs test#{MESSAGE_COMPONENT_SEPARATOR}endtest"
    parts.join(MESSAGE_COMPONENT_SEPARATOR) + EOM
  end

end
=begin
INITSTR = "6	0	start_date	daily	now - 9 months	start_date	hourly	now - 2 months	start_date	30-minute	now - 55 days	start_date	20-minute	now - 1 month	start_date	15-minute	now - 1 month	start_date	10-minute	now - 18 days	start_date	5-minute	now - 18 days	start_date	weekly	now - 4 years	start_date	monthly	now - 8 years	start_date	quarterly	now - 10 years	end_date	daily	now\a"
=end

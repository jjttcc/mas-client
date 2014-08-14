require 'date'
require 'ruby_contracts'
require_relative 'mas_communication_protocol'
require_relative 'time_period_type_constants'
require_relative 'tradable_event'

# Services/tools for communication with the Market-Analysis server
module MasCommunicationServices
  include MasCommunicationProtocol, TimePeriodTypeConstants
  include Contracts::DSL

  public

  attr_reader :session_key, :symbols, :indicators, :period_types,
    :tradable_data, :indicator_data, :analyzers, :analysis_result,
    :tradable_factory

  # start and end date for analysis
  attr_accessor :analysis_start_date, :analysis_end_date

  public ## Access

  # Is this object currently logged in to the server with a valid session
  # key?
  def logged_in
    session_key != nil and session_key.length > 0
  end

  public ## Operations

  # Logout from the server.
  pre :logged_in do logged_in end
  post :not_logged_in do not logged_in end
  def logout
    logout_request = constructed_message([LOGOUT_REQUEST, session_key,
                                          NULL_FIELD])
    begin_communication
    send(logout_request)
    # (No 'receive_response' after logout.)
    end_communication
    finish_logout
    @session_key = nil
  end

  # Request all available tradable symbols from the server and initialize the
  # 'symbols' attribute with this list.
  pre "logged in" do logged_in end
  type @symbols => Array
  def request_symbols
    sym_request = constructed_message([TRADABLE_LIST_REQUEST, session_key,
                                  NULL_FIELD])
    execute_request(sym_request)
    @symbols = list_from_response
  end

  # Request all indicators (TA functions) available for the tradable
  # identified by 'symbol' with 'period_type'.
  pre "logged in" do logged_in end
  pre "args valid" do |sym, ptype| sym != nil and sym.length > 0 and
    ptype != nil and @@period_types.include?(ptype) end
  type @indicators => Array
  def request_indicators(symbol, period_type)
    ind_request = constructed_message([INDICATOR_LIST_REQUEST, session_key,
                                  symbol, period_type])
    execute_request(ind_request)
    @indicators = list_from_response
  end

  # Request all period-types available for the 'symbol'.
  pre "logged in" do logged_in end
  pre "symbol valid" do |symbol| symbol != nil and symbol.length > 0 end
  type @period_types => Array
  def request_period_types(symbol)
    ptype_request = constructed_message([TRADING_PERIOD_TYPE_REQUEST,
                                         session_key, symbol])
    execute_request(ptype_request)
    @period_types = list_from_response
  end

  # Request data for the 'symbol' at 'period_type'.
  pre "logged in" do logged_in end
  pre "args valid" do |sym, ptype| sym != nil and sym.length > 0 and
    ptype != nil and @@period_types.include?(ptype) end
  def request_tradable_data(symbol, period_type)
    data_request = constructed_message([TRADABLE_DATA_REQUEST, session_key,
                                        symbol, period_type])
    execute_request(data_request, method(:process_data_response))
    lines = list_from_response
    @tradable_data = lines.map do |line|
      line.split(MESSAGE_COMPONENT_SEPARATOR)
    end
  end

  # Request indicator - for indicator_id - data for the 'symbol' at
  # 'period_type'.
  type :in => [String, Integer, String]
  pre "logged in" do logged_in end
  pre "args valid" do |sym, ind_id, ptype| sym != nil and sym.length > 0 and
    ptype != nil and @@period_types.include?(ptype) and ind_id >= 0 end
  def request_indicator_data(symbol, indicator_id, period_type)
    data_request = constructed_message([INDICATOR_DATA_REQUEST, session_key,
                                        indicator_id, symbol, period_type])
    execute_request(data_request, method(:process_data_response))
    lines = list_from_response
    @indicator_data = lines.map do |line|
      line.split(MESSAGE_COMPONENT_SEPARATOR)
    end
  end

  # Request data analyzers for the tradable identified by 'symbol'
  # with 'period_type'.
  pre "logged in" do logged_in end
  pre "args valid" do |sym, ptype| sym != nil and sym.length > 0 and
    ptype != nil and @@period_types.include?(ptype) end
  post :analyzers_set do analyzers != nil and analyzers.class == [].class end
  def request_analyzers(symbol, period_type)
    id_index = 1; name_index = 0
    request = constructed_message([EVENT_LIST_REQUEST, session_key,
                                  symbol, period_type])
    execute_request(request, method(:process_data_response))
    lines = list_from_response
    @analyzers = []
    if lines.length > 0
      @analyzers = lines.map do |line|
        parts = line.split(MESSAGE_COMPONENT_SEPARATOR)
        tradable_factory.new_analyzer(id: parts[id_index],
                                      name: parts[name_index])
      end
    end
  end

  DATE_I = 0; TIME_I = 1; ID_I = 2; TYPE_I = 3

  # Request that analysis be performed by the specified list of analyzers
  # on the tradable specified by 'symbol' for the specified date/time range.
  #type :in => [Array, String, Date (optional), Date (optional)]
  pre "logged in" do logged_in end
  pre "symbol valid" do |alist, sym| sym != nil and sym.length > 0 end
  def request_analysis(analyzers, symbol, start_date = analysis_start_date,
                       end_date = analysis_end_date)

    if analyzers == nil
      @@log.warn('request_analysis called before request_analyzers')
      @analysis_result = []
    else
      ids = analyzers.map do |analyzer|
        analyzer.id
      end
      sdate = sprintf "%04d%c%02d%c%02d", start_date.year,
        ANALYSIS_REQ_DATE_FIELD_SEPARATOR, start_date.month,
        ANALYSIS_REQ_DATE_FIELD_SEPARATOR, start_date.day
      edate = sprintf "%04d%c%02d%c%02d", end_date.year,
        ANALYSIS_REQ_DATE_FIELD_SEPARATOR, end_date.month,
        ANALYSIS_REQ_DATE_FIELD_SEPARATOR, end_date.day
      dates = [sdate, edate]
      request = constructed_message([EVENT_DATA_REQUEST, session_key, symbol] +
                                    dates + ids)
      execute_request(request, method(:process_data_response))
      lines = list_from_response
      @analysis_result = lines.map do |line|
        record = line.split(MESSAGE_COMPONENT_SEPARATOR)
        TradableEvent.new(record[DATE_I], record[TIME_I], record[ID_I],
                          record[TYPE_I], analyzers)
      end
    end
  end

  protected

  attr_reader :last_response_components, :last_response,
    :server_closed_connection

  protected ## Hook methods

  # Send 'msg' to the server.
  type :in => String
  pre "msg not empty" do |msg| msg.length > 0 end
  pre "msg ends in EOM" do |msg| msg[-1] == EOM end
  def send(msg)
    raise "abstract method"
  end

  # Obtain the server's response from the last 'send'
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

  # Perform any actions, such as closing the IO medium, needed at the end of
  # a logout.
  def finish_logout
  end

  protected ## Constructed client requests

  # Initial message to the server to start a session
  type :out => String
  post "not empty" do |result| result.length > 0 end
  post "result ends in EOM" do |result| result[-1] == EOM end
  def initial_message
    constructed_message([LOGIN_REQUEST, DUMMY_SESSION_KEY, START_DATE,
                         DAILY, 'now - 36 months'])
  end

  protected ## Protocol-related implementation tools

  # Process response 'r' (String) and initialize last_response_components
  # with the resulting array.
  post "last_response_comp exists" do last_response_components != nil end
  post "last response array" do last_response_components.class == [].class end
  def process_response(r)
    r.sub!(/#{EOM}$/, '')  # Strip off end-of-message character at end.
    @last_response_components = r.split(MESSAGE_COMPONENT_SEPARATOR)
  end

  # The session key, if any, from the last response (stored in
  # last_response_components)
  def key_from_response
    last_response_components[SESSION_KEY_IDX]
  end

  # Array of items obtained from the response (consisting of record-separated
  # values) to the last successful data request
  pre "last_response_comp exists" do last_response_components != nil end
  pre "last_response_comp valid" do last_response_components.length > 0 end
  post "result is array" do |result| result.class == [].class end
  def list_from_response
    result = []
    if last_response_components.length > DATA_IDX
      result =
        last_response_components[DATA_IDX].split(MESSAGE_RECORD_SEPARATOR)
    end
    result
  end

  # Was a successful/OK status resported as part of the last response?
  def response_ok?
    response_code = Integer(last_response_components[MSG_STATUS_IDX])
    response_code == OK or response_code == OK_WILL_NOT_CLOSE
  end

  protected ## Utilities

  # Message, from 'parts' (array of message components), to be sent to the
  # server, with field-separators and EOM added.
  def constructed_message(parts)
    parts.join(MESSAGE_COMPONENT_SEPARATOR) + EOM
  end

  # Set '@server_closed_connection' from the server's response.
  def set_server_closed_connection
    @server_closed_connection = false
    if last_response_components != nil
      response_code = Integer(last_response_components[MSG_STATUS_IDX])
      @server_closed_connection = response_code == OK
    end
  end

  private

  @@log = Logger.new('mas-client.log', 1, 1024000)

  # Send the 'initial_message' to the server, obtain the response, and use
  # it to set the session_key.
  pre :new_analyzer do |*args| args[0][:factory].respond_to?(:new_analyzer) end
  pre :host_port do |*args| ! args[0][:host].nil? && ! args[0][:port].nil? end
  post "logged in" do logged_in end
  post :valid_session_key do session_key =~ /^\d+/ end
  type @analysis_start_date => DateTime, @analysis_end_date => DateTime
  def initialize(*args)
    @tradable_factory = args[0][:factory]
    args[0].delete(:factory)
    initialize_communication(*args)
    execute_request(initial_message)
    @session_key = key_from_response
    analysis_start_date = DateTime.now
    analysis_end_date = DateTime.now
  end

  # Execute the specified 'request' to the server and call process_response
  # with the server's response (in 'last_response').  Check if the server
  # returned OK status, and, if not, raise an appropriate exception.  If
  # 'processor' is not nil, it will be called to process the server's
  # response; otherwise, process_response will be called.
  pre "request valid" do |request| request != nil and request.length > 0 end
  post "last_resp_comp exists" do last_response_components != nil end
  post "last_resp_comp array" do last_response_components.class == [].class end
  def execute_request(request, processor = nil)
    @last_response_components = nil
    send_request(request)
    if processor
      processor.call(last_response)
    else
      process_response(last_response)
    end
    set_server_closed_connection
    if not response_ok?
      raise "Server returned error status: #{last_response}"
    end
  end

  # Send the specified 'request' to the server and call 'receive_response'
  # to obtain the response.
  pre "request valid" do |request| request != nil and request.length > 0 end
  def send_request(request)
    begin_communication
    send(request)
    receive_response
    end_communication
  end

  def process_data_response(response)
    response.sub!(/#{EOM}$/, '')  # Strip off end-of-message character at end.
    @last_response_components = response.split(MESSAGE_COMPONENT_SEPARATOR, 2)
  end

end

#### !!!!TO-DO: Use the string below as a reminder to properly implement complete
#### !!!!setting of time periods on initial login with the server.
=begin
INITSTR = "6	0	start_date	daily	now - 9 months	start_date	hourly	now - 2 months	start_date	30-minute	now - 55 days	start_date	20-minute	now - 1 month	start_date	15-minute	now - 1 month	start_date	10-minute	now - 18 days	start_date	5-minute	now - 18 days	start_date	weekly	now - 4 years	start_date	monthly	now - 8 years	start_date	quarterly	now - 10 years	end_date	daily	now\a"
=end

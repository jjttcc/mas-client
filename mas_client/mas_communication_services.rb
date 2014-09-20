require 'active_support/time'
require 'ruby_contracts'
require_relative 'mas_communication_protocol'
require_relative 'time_period_type_constants'
require_relative 'tradable_event'

# Services/tools for communication with the Market-Analysis server
module MasCommunicationServices
  include MasCommunicationProtocol, TimePeriodTypeConstants
  include Contracts::DSL

  public ### Public attributes

  attr_reader :session_key, :symbols, :indicators, :period_types,
    :tradable_data, :indicator_data, :analyzers, :analysis_data,
    :mas_session, :indicator_parameters, :analysis_parameters, :object_info

  public ### Access

  # Is this object currently logged in to the server with a valid session
  # key?
  def logged_in
    session_key != nil and session_key.length > 0
  end

  type :in => String
  def period_type_spec_for(period_type)
    result = nil
    if period_type_specs != nil
      result = period_type_specs[period_type]
    end
  end

  public  ###  Element change

  pre :pspec_valid do |ps| valid_period_type_spec(ps) end
  def set_period_type_spec(pspec)
    @period_type_specs[pspec.period_type] = pspec
  end

  public ### Client requests

  # Logout from the server.
  pre :logged_in do logged_in end
  post :not_logged_in do not logged_in end
  post :nil_key do session_key == nil end
  def logout
    logout_request = constructed_message([LOGOUT_REQUEST, session_key,
                                          NULL_FIELD])
    begin
      begin_communication
      send(logout_request)
      # (No 'receive_response' after logout.)
      end_communication
    rescue => e
      @@log.warn("'logout' from server failed with error: #{e}")
    end
    finish_logout
    @session_key = nil
  end

  # Request all available tradable symbols from the server and initialize the
  # 'symbols' attribute with this list.
  pre "logged in" do logged_in end
  post :symbols_exist do symbols != nil end
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
  type @tradable_data => Array
  def request_tradable_data(symbol, period_type, start_date = nil,
                            end_date = nil)
    msg_parts = [TRADABLE_DATA_REQUEST, session_key, symbol, period_type]
    if start_date != nil
      msg_parts[0] = TIME_DELIMITED_TRADABLE_DATA_REQUEST
      msg_parts << date_spec(start_date, end_date)
    end
    data_request = constructed_message(msg_parts)
    execute_request(data_request, method(:process_data_response))
    lines = list_from_response
    @tradable_data = lines.map do |line|
      line.split(MESSAGE_COMPONENT_SEPARATOR)
    end
  end

  # Request indicator - for indicator_id - data for the 'symbol' at
  # 'period_type'.
  pre "logged in" do logged_in end
  pre "args valid" do |sym, ind_id, ptype| sym != nil and sym.length > 0 and
    ptype != nil and @@period_types.include?(ptype) and ind_id >= 0 end
  type @indicator_data => Array
  def request_indicator_data(symbol, indicator_id, period_type,
                             start_date = nil, end_date = nil)
    msg_parts = [INDICATOR_DATA_REQUEST, session_key, indicator_id,
                 symbol, period_type]
    if start_date != nil
      msg_parts[0] = TIME_DELIMITED_INDICATOR_DATA_REQUEST
      msg_parts << date_spec(start_date, end_date)
    end
    data_request = constructed_message(msg_parts)
    execute_request(data_request, method(:process_data_response))
    lines = list_from_response
    @indicator_data = lines.map do |line|
      line.split(MESSAGE_COMPONENT_SEPARATOR)
    end
  end

  # Request parameter settings for the specified indicator.
  type :in => String
  pre "logged in" do logged_in end
  pre "args valid" do |ind_name| ind_name.length > 0 end
  type @indicator_parameters => Array
  def request_indicator_parameters(indicator_name)
    request = constructed_message([INDICATOR_PARAMETERS_REQUEST, session_key,
                                   indicator_name])
    execute_request(request, method(:process_data_response))
    @indicator_parameters = []
    fill_parameters_from_response_list(@indicator_parameters)
  end

  # Request modification of parameter settings for the specified indicator.
  # (request format:
  # <ind-name>\t<param-idx1>:<value1>,<param-idx2>:<value2>...)
  type :in => [String, String]
  pre "logged in" do logged_in end
  pre "args valid" do |ind_name, specs|
    ind_name.length > 0 && specs.length > 0 end
  def request_indicator_parameters_modification(indicator_name, param_specs)
    request = constructed_message([INDICATOR_PARAMETERS_SET_REQUEST,
                                   session_key, indicator_name, param_specs])
    execute_request(request)
  end

  # Request parameter settings for the specified analyzer.
  type :in => String
  pre "logged in" do logged_in end
  pre "args valid" do |ana_name| ana_name.length > 0 end
  type @analysis_parameters => Array
  def request_analysis_parameters(analyzer_name)
    request = constructed_message([ANALYSIS_PARAMETERS_REQUEST, session_key,
                                   analyzer_name])
    execute_request(request, method(:process_data_response))
    @analysis_parameters = []
    fill_parameters_from_response_list(@analysis_parameters)
  end

  # Request modification of parameter settings for the specified analyzer.
  # (request format:
  # <ana-name>\t<param-idx1>:<value1>,<param-idx2>:<value2>...)
  type :in => [String, String]
  pre "logged in" do logged_in end
  pre "args valid" do |ind_name, specs|
    ind_name.length > 0 && specs.length > 0 end
  def request_analysis_parameters_modification(analyzer_name, param_specs)
    request = constructed_message([ANALYSIS_PARAMETERS_SET_REQUEST,
                                   session_key, analyzer_name, param_specs])
    execute_request(request)
  end

  # Request data analyzers for the tradable identified by 'symbol'
  # with 'period_type'.
  pre "logged in" do logged_in end
  pre "args valid" do |sym, ptype| sym != nil and sym.length > 0 and
    (ptype == nil || @@period_types.include?(ptype)) end
  post :analyzers_set do analyzers != nil and analyzers.class == [].class end
  post :analyzers_have_id_name do
    @analyzers.all? {|a| a.respond_to?(:id) && a.respond_to?(:name)} end
  type @analyzers => Array
  def request_analyzers(symbol, period_type = DAILY)
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
                            name: parts[name_index], period_type: period_type)
      end
    end
  end

  DATE_I = 0; TIME_I = 1; ID_I = 2; TYPE_I = 3

  # Request that analysis be performed by the specified list of analyzers
  # on the tradable specified by 'symbol' for the specified date/time range.
  #type :in => [Array, String, Date (optional), Date (optional)]
  pre :logged_in do logged_in end
  pre :args_valid do |alist, sym, sdate| sym != nil and sym.length > 0 and
    sdate != nil and (sdate.class == Date || sdate.class == DateTime) end
  pre :analyzers_have_id do |analyzers|
    implies(analyzers != nil, analyzers.all? {|a| a.respond_to?(:id)}) end
  post :analysis_data_exists do @analysis_data != nil end
  def request_analysis(analyzers, symbol, start_date, end_date = nil)
    if analyzers == nil
      @@log.warn('request_analysis called before request_analyzers')
      @analysis_data = []
    else
      ids = analyzers.map do |analyzer|
        analyzer.id
      end
      sdate = sprintf "%04d%c%02d%c%02d", start_date.year,
        ANALYSIS_REQ_DATE_FIELD_SEPARATOR, start_date.month,
        ANALYSIS_REQ_DATE_FIELD_SEPARATOR, start_date.day
      if end_date == nil
        edate = 'now'
      else
        edate = sprintf "%04d%c%02d%c%02d", end_date.year,
          ANALYSIS_REQ_DATE_FIELD_SEPARATOR, end_date.month,
          ANALYSIS_REQ_DATE_FIELD_SEPARATOR, end_date.day
      end
      dates = [sdate, edate]
      request = constructed_message([EVENT_DATA_REQUEST, session_key, symbol] +
                                    dates + ids)
      execute_request(request, method(:process_data_response))
      lines = list_from_response
      @analysis_data = lines.map do |line|
        record = line.split(MESSAGE_COMPONENT_SEPARATOR)
        tradable_factory.new_event(date: record[DATE_I], time: record[TIME_I],
                                   id: record[ID_I], type_id: record[TYPE_I],
                                   analyzers: analyzers)
      end
    end
  end

  # Request information for the specified objects.
  type in: Array
  pre :logged_in do logged_in end
  post :object_info_exists do @object_info != nil end
  post :object_info_strings do implies(object_info.count > 0,
                                       object_info[0].class == String) end
  type @object_info => Array
  def request_object_info(object_list)
    obj_inf_req = ''
    (0..object_list.count-2).each do |i|
      obj_inf_req << "#{object_list[i].type},#{object_list[i].name}"
      if object_list[i].options != nil
        obj_inf_req << ",#{object_list[i].options}"
      end
      obj_inf_req << "\n"
    end
    obj_inf_req << "#{object_list[-1].type},#{object_list[-1].name}"
    obj_inf_req << ",#{object_list[-1].options}"
    request = constructed_message([OBJECT_INFO_REQUEST, session_key,
                                   obj_inf_req])
    execute_request(request)
    data = string_blob_from_response
    @object_info = data.split(OBJECT_SEPARATOR)
  end

  public ### Utilities

  # Does 'arg' contain valid period-type specifications?
  pre :arg_exists do |arg| arg != nil end
  post :valid_if_absent do |res, arg|
    implies(arg[:period_types].nil? && arg['period.*'].nil?, res) end
  def valid_period_types(arg)
    result = true
    ptypes = arg[:period_types]
    ptypes ||= arg['period.*']
    if ptypes
      result = ptypes.respond_to?('[]')
      if result
        ptypes.each do |ptype|
          if not valid_period_type_spec(ptype)
            result = false
            break
          end
        end
      end
    end
    result
  end

  # Is 'ptype_spec' a valid period-type specification?
  pre :arg_exists do |ptype_spec| ptype_spec != nil end
  def valid_period_type_spec(ptype_spec)
    ptype_spec.respond_to?(:period_type) and
      ptype_spec.respond_to?(:start_date) and
      ptype_spec.respond_to?(:end_date)
  end

  protected ### Non-public attributes

  attr_reader :last_response_components, :last_response,
    :server_closed_connection, :period_type_specs, :tradable_factory


  protected ### Hook methods

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

  protected ### Constructed client requests

  # Initial message to the server to start a session
  type :out => String
  post "not empty" do |result| result.length > 0 end
  post "result ends in EOM" do |result| result[-1] == EOM end
  def initial_message
    specs = period_type_specs
    result = ''
    if specs != nil && ! specs.empty?
      Time.zone = 'UTC'; now = Time.zone.now.to_date
      message_components = [LOGIN_REQUEST, DUMMY_SESSION_KEY]
      specs.values.each do |spec|
        message_components << [START_DATE, spec.period_type,
           "now - #{(now - spec.start_date.to_date).floor} days"]
        end_spec = 'now'
        if spec.end_date != nil
          end_spec << " - #{(now - spec.end_date.to_date).floor} days"
        end
        message_components << [END_DATE, spec.period_type, end_spec]
      end
      result = constructed_message(message_components)
    else
      result = constructed_message([LOGIN_REQUEST, DUMMY_SESSION_KEY,
                                    START_DATE, DAILY, 'now - 36 months'])
    end
    result
  end

  protected ### Protocol-related implementation tools

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
  type :out => Array
  def list_from_response
    result = []
    if last_response_components.length > DATA_IDX
      result =
        last_response_components[DATA_IDX].split(MESSAGE_RECORD_SEPARATOR)
    end
    result
  end

  # All data from the response as a single string - i.e., not split into
  # records, fields, or other components
  pre "last_response_comp exists" do last_response_components != nil end
  pre "last_response_comp valid" do last_response_components.length > 0 end
  def string_blob_from_response
    result = []
    if last_response_components.length > DATA_IDX
      result = last_response_components[DATA_IDX]
    end
    result
  end

  # Was a successful/OK status resported as part of the last response?
  def response_ok?
    response_code = Integer(last_response_components[MSG_STATUS_IDX])
    response_code == OK or response_code == OK_WILL_NOT_CLOSE
  end

  private

  @@log = Logger.new('mas-client.log', 1, 1024000)

  # Send the 'initial_message' to the server, obtain the response, and use
  # it to set the session_key.
  pre :new_analyzer do |args| args[:factory].respond_to?(:new_analyzer) end
  pre :host_port do |args| ! args[:host].nil? && ! args[:port].nil? end
  pre :valid_period_types do |args| valid_period_types(args) end
  post "logged in" do logged_in end
  post :valid_session_key do session_key =~ /^\d+/ end
  type @session_key => String
  def initialize(args)
    @tradable_factory = args[:factory]
    @mas_session = args[:mas_session]
    if mas_session
      @session_key = mas_session.mas_session_key.to_s
    end
    init_ptype_specs(args['period.*type'])
    initialize_communication(args[:host], args[:port], args[:close_after_w])
    if mas_session.nil?
      @@log.debug('No mas session yet - need to log in.')
      execute_request(initial_message)
      @session_key = key_from_response
    end
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

  protected ### Utilities

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
      @server_closed_connection = response_code >= WILL_CLOSE_BOTTOM &&
        response_code <= WILL_CLOSE_TOP
    end
  end

  def init_ptype_specs(specs)
    if @period_type_specs.nil?
      @period_type_specs = {}
    end
    if specs != nil
      specs.each do |s|
        @period_type_specs[s.period_type] = s
      end
    end
  end

  # start and end date (end can be nil) in the format expected by the
  # server
  pre :start_date_exists do |sdt| sdt != nil end
  def date_spec(start_date, end_date)
    date_sep = DATA_REQ_DATE_FIELD_SEPARATOR
    format = "%0Y#{date_sep}%0m#{date_sep}%0d"
    result = start_date.strftime(format)
    if end_date != nil
      result += START_END_DATE_SEPARATOR + end_date.strftime(format)
    end
    result
  end

  def fill_parameters_from_response_list(param_array)
    name_index, value_index, type_index = 0, 1, 2
    lines = list_from_response
    if lines.length > 0
      (0..lines.count-1).each do |i|
        parts = lines[i].split(MESSAGE_COMPONENT_SEPARATOR)
        param_array << tradable_factory.new_parameter(name: parts[name_index],
                    type_desc: parts[type_index], value: parts[value_index])
      end
    end
  end

end

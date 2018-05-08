module ParameterTestTools

  IND_PARAM_VALUE_MAP = {
    "MACD Difference" => {
      "1:n-value - EMA, Short" => 15,
      "2:n-value - EMA, Long" => 7,
    },
    "MACD Signal Line (EMA of MACD Difference)" => {
      "1:n-value - EMA, Short" => 15,
      "2:n-value - EMA, Long" => 7,
      "3:n-value - MACD Signal Line (EMA of MACD Difference)" => 6,
    },
    "Slope of MACD Signal Line" => {
      "1:n-value - MACD Signal Line (EMA of MACD Difference)" => 15,
      "2:n-value - EMA, Short" => 7,
      "3:n-value - EMA, Long" => 9,
    },
    "Simple Moving Average" => {
      "1:n-value - Simple Moving Average" => 17,
    },
    "Exponential Moving Average" => {
      "1:n-value - Exponential Moving Average" => 17,
    },
  }

  ANA_PARAM_VALUE_MAP = {
    "MACD Crossover (Buy)" => {
      "1:n-value - EMA, Short" => 5,
      "2:n-value - EMA, Long" => 13,
      "3:n-value - EMA, Short" => 8,
      "4:n-value - EMA, Long" => 13,
      "5:n-value - MACD Signal Line (EMA of MACD Difference)" => 6,
    },
    "MACD Crossover (Sell)" => {
      "1:n-value - EMA, Short" => 5,
      "2:n-value - EMA, Long" => 13,
      "3:n-value - EMA, Short" => 5,
      "4:n-value - EMA, Long" => 13,
      "5:n-value - MACD Signal Line (EMA of MACD Difference)" => 6,
    },
    "Stochastic %D Crossover (Buy)" => {
      "1:n-value - Stochastic: moving average of 'close' - 'n-period low'" => 3,
      "2:n-value - Stochastic: 'close' - 'n-period low'" => 5,
      "3:n-value - Stochastic: moving average of 'n-period high' - 'n-period low'" => 3,
      "4:n-value - Stochastic: 'n-period high' - 'n-period low'" => 5,
      "5:slope - Line" => 0,
      "6:y-value for the left-most point - Line" => 35,
    },
    "Stochastic %D Crossover (Sell)" => {
      "1:n-value - Stochastic: moving average of 'close' - 'n-period low'" => 3,
      "2:n-value - Stochastic: 'close' - 'n-period low'" => 5,
      "3:n-value - Stochastic: moving average of 'n-period high' - 'n-period low'" => 3,
      "4:n-value - Stochastic: 'n-period high' - 'n-period low'" => 5,
      "5:slope - Line" => 0,
      "6:y-value for the left-most point - Line" => 65,
    },
    "Slope of MACD Signal Line Cross Above 0 (Buy)" => {
      "1:n-value - MACD Signal Line (EMA of MACD Difference)" => 6,
      "2:n-value - EMA, Short" => 5,
      "3:n-value - EMA, Long" => 13,
      "4:slope - Line" => 0,
      "5:y-value for the left-most point - Line" => 0,
    },
    "Slope of MACD Signal Line Cross Below 0 (Sell)" => {
      "1:n-value - MACD Signal Line (EMA of MACD Difference)" => 6,
      "2:n-value - EMA, Short" => 5,
      "3:n-value - EMA, Long" => 13,
      "4:slope - Line" => 0,
      "5:y-value for the left-most point - Line" => 0,
    },
    "Slope of Slope of MACD Signal Line Cross Above 0 (Buy)" => {
      "1:n-value - MACD Signal Line (EMA of MACD Difference)" => 6,
      "2:n-value - EMA, Short" => 5,
      "3:n-value - EMA, Long" => 13,
      "4:slope - Line" => 0,
      "5:y-value for the left-most point - Line" => 0,
    },
    "Slope of Slope of MACD Signal Line Cross Below 0 (Sell)" => {
      "1:n-value - MACD Signal Line (EMA of MACD Difference)" => 6,
      "2:n-value - EMA, Short" => 5,
      "3:n-value - EMA, Long" => 13,
      "4:slope - Line" => 0,
      "5:y-value for the left-most point - Line" => 0,
    },
    "Volume > Yesterday's Volume EMA (5) * 3.5" => {
    },
    "MACD Crossover and Stochastic %D Crossover (Buy)" => {
      "10:slope - Line" => 0,
      "11:y-value for the left-most point - Line" => 35,
      "1:n-value - EMA, Short" => 5,
      "2:n-value - EMA, Long" => 13,
      "3:n-value - EMA, Short" => 5,
      "4:n-value - EMA, Long" => 13,
      "5:n-value - MACD Signal Line (EMA of MACD Difference)" => 6,
      "6:n-value - Stochastic: moving average of 'close' - 'n-period low'" => 3,
      "7:n-value - Stochastic: 'close' - 'n-period low'" => 5,
      "8:n-value - Stochastic: moving average of 'n-period high' - 'n-period low'" => 3,
      "9:n-value - Stochastic: 'n-period high' - 'n-period low'" => 5,
    },
    "MACD Crossover and Stochastic %D Crossover (Sell)" => {
      "10:slope - Line" => 0,
      "11:y-value for the left-most point - Line" => 65,
      "1:n-value - EMA, Short" => 5,
      "2:n-value - EMA, Long" => 13,
      "3:n-value - EMA, Short" => 5,
      "4:n-value - EMA, Long" => 13,
      "5:n-value - MACD Signal Line (EMA of MACD Difference)" => 6,
      "6:n-value - Stochastic: moving average of 'close' - 'n-period low'" => 3,
      "7:n-value - Stochastic: 'close' - 'n-period low'" => 5,
      "8:n-value - Stochastic: moving average of 'n-period high' - 'n-period low'" => 3,
      "9:n-value - Stochastic: 'n-period high' - 'n-period low'" => 5,
    },
    "Slope of MACD Signal Line Downtrend" => {
      "10:{Limit} (Numeric value)" => 0.17499999701976776,
      "11:{True result} (Numeric value)" => 1,
      "12:{False result} (Numeric value)" => 0,
      "13:slope - Line" => 0,
      "14:y-value for the left-most point - Line" => -0.5,
      "1:n-value - MACD Signal Line (EMA of MACD Difference)" => 6,
      "2:n-value - EMA, Short" => 5,
      "3:n-value - EMA, Long" => 13,
      "4:n-value - MACD Signal Line (EMA of MACD Difference)" => 6,
      "5:n-value - EMA, Short" => 5,
      "6:n-value - EMA, Long" => 13,
      "7:{Limit} (Numeric value)" => -0.17499999701976776,
      "8:{True result} (Numeric value)" => -1,
      "9:{False result} (Numeric value)" => 0,
    },
    "Slope of MACD Signal Line Uptrend" => {
      "10:{Limit} (Numeric value)" => 0.17499999701976776,
      "11:{True result} (Numeric value)" => 1,
      "12:{False result} (Numeric value)" => 0,
      "13:slope - Line" => 0,
      "14:y-value for the left-most point - Line" => 0.5,
      "1:n-value - MACD Signal Line (EMA of MACD Difference)" => 6,
      "2:n-value - EMA, Short" => 5,
      "3:n-value - EMA, Long" => 13,
      "4:n-value - MACD Signal Line (EMA of MACD Difference)" => 6,
      "5:n-value - EMA, Short" => 5,
      "6:n-value - EMA, Long" => 13,
      "7:{Limit} (Numeric value)" => -0.17499999701976776,
      "8:{True result} (Numeric value)" => -1,
      "9:{False result} (Numeric value)" => 0,
    },
    "Slope of MACD Signal Line Trend Sideways: 1 to 0" => {
      "10:{Limit} (Numeric value)" => 0.17499999701976776,
      "11:{True result} (Numeric value)" => 1,
      "12:{False result} (Numeric value)" => 0,
      "13:slope - Line" => 0,
      "14:y-value for the left-most point - Line" => 0.5,
      "1:n-value - MACD Signal Line (EMA of MACD Difference)" => 6,
      "2:n-value - EMA, Short" => 5,
      "3:n-value - EMA, Long" => 13,
      "4:n-value - MACD Signal Line (EMA of MACD Difference)" => 6,
      "5:n-value - EMA, Short" => 5,
      "6:n-value - EMA, Long" => 13,
      "7:{Limit} (Numeric value)" => -0.17499999701976776,
      "8:{True result} (Numeric value)" => -1,
      "9:{False result} (Numeric value)" => 0,
    },
    "Slope of MACD Signal Line Trend Sideways: -1 to 0" => {
      "10:{Limit} (Numeric value)" => 0.17499999701976776,
      "11:{True result} (Numeric value)" => 1,
      "12:{False result} (Numeric value)" => 0,
      "13:slope - Line" => 0,
      "14:y-value for the left-most point - Line" => -0.5,
      "1:n-value - MACD Signal Line (EMA of MACD Difference)" => 6,
      "2:n-value - EMA, Short" => 5,
      "3:n-value - EMA, Long" => 13,
      "4:n-value - MACD Signal Line (EMA of MACD Difference)" => 6,
      "5:n-value - EMA, Short" => 5,
      "6:n-value - EMA, Long" => 13,
      "7:{Limit} (Numeric value)" => -0.17499999701976776,
      "8:{True result} (Numeric value)" => -1,
      "9:{False result} (Numeric value)" => 0,
    },
    "CCI Crossed above x" => {
      "1:n-value - Commodity Channel Index" => 5,
      "2:{Multiplier constant} (Numeric value)" => 0.014999999664723873,
      "3:slope - Line" => 0,
      "4:y-value for the left-most point - Line" => 100,
    },
    "CCI Crossed below -x" => {
      "1:n-value - Commodity Channel Index" => 5,
      "2:{Multiplier constant} (Numeric value)" => 0.014999999664723873,
      "3:slope - Line" => 0,
      "4:y-value for the left-most point - Line" => -100,
    }
  }

  # Default to inidicators:
  @param_settings_for = IND_PARAM_VALUE_MAP

  def switch_to_inidicators
    @param_settings_for = IND_PARAM_VALUE_MAP
  end

  def switch_to_analyzers
    @param_settings_for = ANA_PARAM_VALUE_MAP
  end

  # The client-request (for the MAS server) for indicator with `indname'
  # If 'pnames_to_include' is not nil, only those parameters, p, whose name
  # such that pnames_to_include[p.name] == true will be used to construct
  # the request.
  def client_request_for(indname, pnames_to_include = nil)
    value_for = @param_settings_for[indname]
#!!!!!Get rid of <sorted...>????!!!!
    sorted_names = value_for.keys.sort
    result = []
    (0 .. sorted_names.count-1).each do |i|
      if pnames_to_include.nil? || pnames_to_include[sorted_names[i]] then
        result << "#{i+1}:#{value_for[sorted_names[i]]}"
      end
    end
    result.join(",")
  end

  # The value, from @param_settings_for, for parameter 'param_name' of
  # indicator 'ind_name'
  def value_for(ind_name, param_name)
    @param_settings_for[ind_name][param_name].to_s
  end

  def change_param_value(ind_name, param_name, value)
    @param_settings_for[ind_name][param_name] = value
  end

  # A mapping of each element 'o' (of 'objs') to the number of times
  # 'o.name' occurs in 'objs' (expected to be an Array).
  # Result: hash table: o => occurrences
  # verbose => report # of occurrences of each object, by name, in result.
  def duplicate_names(objs, verbose = false)
    name_to_dupcount = {}
    name_to_obj = objs.map{ |o| [o.name, o] }.to_h
    objs.each do |o|
      if name_to_dupcount.has_key?(o.name) then
        name_to_dupcount[o.name] += 1
      else
        name_to_dupcount[o.name] = 1
      end
    end
    result = {}
    name_to_dupcount.keys.each do |name|
      if name_to_dupcount[name] > 1 then
        result[name_to_obj[name]] = name_to_dupcount[name]
      end
      if verbose then
        $stderr.puts "object with name <#{name}> has: " +
          "#{name_to_dupcount[name]} occurrences"
      end
    end
    result
  end

end

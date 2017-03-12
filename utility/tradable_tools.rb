begin
  require 'global_log'
rescue LoadError => e
  require_relative 'global_log'
end

# Tools for getting various data about stocks, commodities, etc.
# (Currently [q2/2017], all this class does is retrieve the company name,
# given a stock symbol; however its name and description have been made
# pretty general to allow the addition of related features - such as
# sector, industry, etc.)
class TradableTools

  public

  SYMBOL, NAME = :symbol, :name

  # Hash table, keyed by symobl
  attr_accessor :tradable_data

  # Clear any cached data.
  # postcondition: tradable_data.empty?
  def clear
    @tradable_data.clear
  end

  # The company name associated with 'symbol'
  def name_for(symbol)
    result = @tradable_data[symbol]
    if result.nil? then
      retrieve_names([symbol])
      result = @tradable_data[symbol]
    end
    result
  end

  # The set of company names (Array) associated with each element of
  # 'symbols', in the order specified
  def names_for(symbols)
    result, missing = [], []
    symbols.each do |s|
      if ! @tradable_data[s] then
        missing << s
      end
    end
    if ! missing.empty? then
      retrieve_names(missing)
    end
    symbols.each do |s|
      if ! @tradable_data[s] then
        # Query for 's' failed, map it to an empty name:
        @tradable_data[s] = ""
      end
      result << @tradable_data[s]
    end
    result
  end

  def invariant
    ! tradable_data.nil?
  end

  private

  def initialize
    @tradable_data = {}
  end

  NOT_APPLICABLE = 'N/A'

  # Modify tradable_data with the result of querying for the data
  # associated with symbols (Array).
  def retrieve_names(symbols)
    require 'open-uri'
    symquery = symbols.join('+')
    open("http://finance.yahoo.com/d/quotes.csv?s=#{symquery}&f=sn") do |f|
      f.each_line do |line|
        line.gsub!(/"/, "")
        sym, name = line.split(',')
        name.chomp!
        if name == NOT_APPLICABLE then
          # Replace 'N/A' with empty string.
          name = ""
        end
        @tradable_data[sym] = name
      end
    end
  end

end

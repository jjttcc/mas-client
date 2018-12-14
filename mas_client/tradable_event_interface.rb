#!/usr/bin/env ruby

require 'ruby_contracts'


# Events or signals generated from analysis of tradable data
module TradableEventInterface
  include Contracts::DSL

  public

  TYPE_TABLE = {
    'b' => 'Buy',
    's' => 'Sell',
    'n' => 'Nuetral (Buy-or-Sell)',
    'o' => 'Other (User-defined)',
  }

  public ### Abstract methods

  # The associated TradableAnalyzer
  def analyzer
    raise "abstract method: analyzer"
  end

  # The date and time that the underlying event occurred (e.g., if the
  # event consists of one moving average line crossing another moving
  # average line, the date/time [based on the underlying associated
  # stock/derivitave data record] associated with this crossover event)
  def datetime
    raise "abstract method: datetime"
  end

  type out: String
  post :id_valid do |result| TYPE_TABLE.has_key?(result) end
  def event_type_id
    raise "abstract method: event_type_id"
  end

  public ### Access

  type out: String
  def event_type
    TYPE_TABLE[event_type_id]
  end

  def to_s
    result = "date: #{datetime.to_s}"
    if ! analyzer.nil? then
      result += ", event name: #{analyzer.name}"
    end
    result += ", event type: #{event_type}"
    result
  end

end

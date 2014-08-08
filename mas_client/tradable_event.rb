#!/usr/bin/env ruby

require 'ruby_contracts'


# Events or signals generated from analysis of tradable data
class TradableEvent
  include Contracts::DSL

  public

  TYPE_TABLE = {
    'b' => 'Buy',
    's' => 'Sell',
    'n' => 'Nuetral (Buy-or-Sell)',
    'o' => 'Other (User-defined)',
  }

  # analyzer: associated TradableAnalyzer; type_id: event-type id
  attr_reader :datetime, :analyzer, :type_id

  public

  def type
    TYPE_TABLE[type_id]
  end

  def to_s
    result = "date: #{datetime.to_s}\n" + "event name: #{analyzer.name}, " +
      "event type: #{type}"
    result
  end

  private

  attr_reader :socket

  def initialize(date, time, analyzer_id, type_id, analyzers)
    @datetime = DateTime.new(date[0..3].to_i, date[4..5].to_i, date[6..7].to_i,
                             time[0..1].to_i, time[2..3].to_i, time[4..5].to_i)
    @type_id = type_id
    a = analyzers.select {|a| a.id == analyzer_id }
    if a.length == 0
      raise "TradableEvent - initialize: analyzer_id arg, #{analyzer_id} " +
        "does not identify any known analyzer."
    else
      @analyzer = a[0]
    end
  end

end

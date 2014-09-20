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

  # analyzer: associated TradableAnalyzer
  attr_reader :datetime, :analyzer, :event_type_id

  public

  def event_type
    TYPE_TABLE[event_type_id]
  end

  def to_s
    result = "date: #{datetime.to_s}\n" + "event name: #{analyzer.name}, " +
      "event type: #{event_type}"
    result
  end

  private

  def initialize(datetime, type_id, analyzer)
    @datetime = datetime
    @event_type_id = type_id
    @analyzer = analyzer
  end

end

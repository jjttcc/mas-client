#!/usr/bin/env ruby

require 'ruby_contracts'
require_relative '../mas_client/tradable_event_interface'


# Events or signals generated from analysis of tradable data
class TestTradableEvent
  include TradableEventInterface, Contracts::DSL

  public

  attr_reader :datetime, :analyzer, :event_type_id

  private

  def initialize(datetime, type_id, analyzer)
    @datetime = datetime
    @event_type_id = type_id
    @analyzer = analyzer
  end

end

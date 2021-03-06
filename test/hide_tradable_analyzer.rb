#!/usr/bin/env ruby

require 'ruby_contracts'


# Client-side representation of objects on the server side responsible for
# analyzing tradable data and resulting producing signal output
class TradableAnalyzer
  include Contracts::DSL

  public

  attr_reader :name, :event_id, :is_intraday

  public ###  Access

  def description
    result = @name.sub(/\s*\(.*/, '')
  end

  private

  def initialize(name, id, intraday = false)
    @name = name
    @event_id = id
    @is_intraday = intraday
  end

end

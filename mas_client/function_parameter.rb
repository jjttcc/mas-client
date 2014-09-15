#!/usr/bin/env ruby

require 'ruby_contracts'


# Client-side representation of objects on the server side responsible for
# holding parameters to function objects (i.e., indicators or
# event-generators)
class FunctionParameter
  include Contracts::DSL

  public

  attr_reader :name, :type_desc, :value

  public ###  Status report

  def valid?
    if type_desc =~ /integer/
      value.is_integer
    elsif type_desc =~ /real/
      value.is_real
    else
      false
    end
  end

  private

  def initialize(name, type_desc, value)
    @name = name
    @type_desc = type_desc
    @value = value
  end

end

class String
  def is_integer
    self =~ /^[-+]?\d+$/
  end

  def is_real
    if Float(self) then true end rescue false
  end

end

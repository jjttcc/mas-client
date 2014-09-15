# Specification for MAS object-information request
class ObjectSpec

  attr_accessor :type, :name, :options

  private

  def initialize(type, name, opts = nil)
    @type = type
    @name = name
    @options = opts
  end

end

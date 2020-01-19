# Pairs of objects
class Pair

  private

  ##### Initialization

  post :set do self.first == l and self.second == r end
  def initialize(l, r)
    @first = l
    @second = r
  end

  public

  ##### Access

  # First element of the pair
  attr_reader :first

  # Second element of the pair
  attr_reader :second

  # Left element of the pair - synonym for `first'
  def left
    self.first
  end

  # Right element of the pair - synonym for `second'
  def right
    self.second
  end

  # Printable representation
  def to_s
    f, s = "", ""
    if first.nil? then
      f = "-void-"
    else
      f = first.to_s
    end
    if second.nil? then
      s = "-void-"
    else
      s = second.to_s
    end
    result = "(" + f + ", " + s + ")"
  end

##### Element change

  alias_method :set_first, :set_left
  alias_method :set_second, :set_right

  # Set `first' (`left') to `arg'.
  post :first_set do first == arg end
  def set_left(arg)
    @first = arg
  end

  # Set `second' (`right') to `arg'.
  post :second_set do second == arg end
  def set_right(arg)
    @second = arg
  end

  def invariant
    # left_is_synonym_for_first:
    left == first
    # right_is_synonym_for_second:
    right == second
  end

end

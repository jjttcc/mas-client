# Pairs of objects
class Pair [g, H]

inherit

  ANY
    redefine
      out
    end

creation

  make

private

##### Initialization

  make (l: G; r: H)
    do
      first := l
      second := r
    ensure
      set: first = l and second = r
    end

  public

  ##### Access

  first: G
      # First element of the pair

  second: H
      # Second element of the pair

  left: G
      # Left element of the pair - synonym for `first'
    do
      Result := first
    end

  right: H
      # Right element of the pair - synonym for `second'
    do
      Result := second
    end

  out: STRING
      # Printable representation
    local
      f, s: STRING
    do
      if first = Void then
        f := "-void-"
      else
        f := first.out
      end
      if second = Void then
        s := "-void-"
      else
        s := second.out
      end
      Result := "(" + f + ", " + s + ")"
    end

##### Element change

  set_first, set_left (arg: G)
      # Set `first' (`left') to `arg'.
    do
      first := arg
    ensure
      first_set: first = arg
    end

  set_second, set_right (arg: H)
      # Set `second' (`right') to `arg'.
    do
      second := arg
    ensure
      second_set: second = arg
    end

invariant

  left_is_synonym_for_first: left = first
  right_is_synonym_for_second: right = second

end -- class PAIR

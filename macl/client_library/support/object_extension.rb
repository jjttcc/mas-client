# !!!!!Find the right place/directory to put this file!!!!!

class Object
  def deferred
    raise "Fatal: abstract method: #{self.class} #{__method__}"
  end
end

class String
  def is_integer?
    self.to_i.to_s == self
  end

  def is_integer
    self.to_i.to_s == self
  end
end

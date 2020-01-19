# Regular-expression utility routines - depends on GOBO
module RegularExpressionUtilities
  include Contracts::DSL

  public

  ##### Status report

  # Did the last compilation of a regular expression fail?
  attr_reader :last_compile_failed

  # The last regular expression processed by `match'
  attr_reader :last_regular_expression

  ##### Basic operations

  # Does `s' match the regular expression `pattern'?
  pre  :args_exist do |ptrn, s| ptrn != nil && s != nil end
  post :last_regular_expression_exists do
    self.last_regular_expression != nil end
  def match(pattern, s)
    regexp = Regexp.compile(pattern)
    result = regexp.match?(s)
    @last_regular_expression = regexp
    @last_compile_failed = false
    result
  end

  # The result of replacing the first occurrence of
  # `pattern' in `target' by `replacement'.  `target' remains
  # unchanged.  If `pattern' is not found in `target' result
  # is equal to target.
  pre  :args_exist do |pattern, replacement, target|
    pattern != nil and replacement != nil and target != nil end
  post :result_is_target_if_no_match do |result, pattern, r, target|
    implies(! match(pattern, target), result == target) end
  def sub(pattern, replacement, target)
    target.sub(pattern, replacement)
  end

  # The result of replacing all occurrence of
  # `pattern' in `target' by `replacement'.  `target' remains
  # unchanged.  If `pattern' is not found in `target' Result
  # is equal to target.
  def gsub(pattern, replacement, target)
    target.gsub(pattern, replacement)
  end

  # Does `target' match at least one element of `patterns'?
  pre :args_exist do |ptrns, tgt| ptrns != nil and tgt != nil end
  def one_pattern_matches(patterns, target)
    result = patterns.any? {|p| match(p, target) }
  end

  # Does `target' match all elements of `patterns'?
  pre :args_exist do |ptrns, tgt| ptrns != nil and tgt != nil end
  def all_patterns_match(patterns, target)
    result = patterns.all? {|p| match(p, target) }
  end

end

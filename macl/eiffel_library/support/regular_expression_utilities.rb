# Regular-expression utility routines - depends on GOBO
class RegularExpressionUtilities

  public

  ##### Status report

  last_compile_failed: BOOLEAN
      # Did the last compilation of a regular expression fail?

  last_regular_expression: RX_PCRE_REGULAR_EXPRESSION
      # The last regular expression processed by `match'

  ##### Basic operations

  match (pattern, s: STRING): BOOLEAN
      # Does `s' match the regular expression `pattern'?
    require
      args_exist: pattern /= Void and s /= Void
    local
      regexp: RX_PCRE_REGULAR_EXPRESSION
    do
      if last_regular_expression = Void then
        create last_regular_expression.make
        last_regular_expression.set_anchored (false)
      end
      regexp := last_regular_expression
      regexp.compile (pattern)
      if regexp.is_compiled then
        regexp.set_anchored (false)
        regexp.match (s)
        Result :=  regexp.has_matched
      end
      last_compile_failed := not regexp.is_compiled
    ensure
      last_regular_expression_exists: last_regular_expression /= Void
      last_compile_failed_definition:
        not last_regular_expression.is_compiled = last_compile_failed
    end

  sub (pattern, replacement, target: STRING): STRING
      # The result of replacing the first occurrence of
      # `pattern' in `target' by `replacement'.  `target' remains
      # unchanged.  If `pattern' is not found in `target' Result
      # is equal to target.
    require
      args_exist: pattern /= Void and replacement /= Void and
        target /= Void
    do
      if match (pattern, target) then
        Result := last_regular_expression.replace (replacement)
      else
        Result := target
      end
    ensure
      result_is_target_if_no_match:
        not match (pattern, target) implies Result = target
    end

  gsub (pattern, replacement, target: STRING): STRING
      # The result of replacing all occurrence of
      # `pattern' in `target' by `replacement'.  `target' remains
      # unchanged.  If `pattern' is not found in `target' Result
      # is equal to target.
    require
      args_exist: pattern /= Void and replacement /= Void and
        target /= Void
    do
      if match (pattern, target) then
        Result := last_regular_expression.replace_all (replacement)
      else
        Result := target
      end
    ensure
      result_is_target_if_no_match:
        not match (pattern, target) implies Result = target
    end

  split (pattern, target: STRING): ARRAY [STRING]
      # Parts of `target' that do not match `pattern'
    require
      args_exist: pattern /= Void and target /= Void
    do
      if match (pattern, target) then
        # Null instruction
      end
      Result := last_regular_expression.split
    ensure
      result_is_target_if_no_match: Result /= Void and
        not match (pattern, target) implies Result.count = 1 and
        Result.item (1).is_equal (target)
    end

  one_pattern_matches (patterns: LINEAR [STRING]; target: STRING): BOOLEAN
      # Does `target' match at least one element of `patterns'?
    require
      args_exist: patterns /= Void and target /= Void
    do
      Result := patterns.linear_representation.there_exists (
        agent match (?, target))
    end

  all_patterns_match (patterns: LINEAR [STRING]; target: STRING): BOOLEAN
      # Does `target' match all elements of `patterns'?
    require
      args_exist: patterns /= Void and target /= Void
    do
      Result := patterns.linear_representation.for_all (
        agent match (?, target))
    end

end

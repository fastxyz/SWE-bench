requires "mini-duration-expressions.k"

module DURATION-EXPRESSION-SPEC
  imports MINI-DURATION-EXPRESSIONS

  // CLAIM: DURATION-FIELD-PLUS-LITERAL
  // SPEC-PROVENANCE:
  // - E1/E2: Reported DurationField + timedelta must work on SQLite/MySQL.
  // - E3: Non-native DurationField storage is integer microseconds.
  claim <k>
    compileDurationExpression(add, col(duration), durValue(D:Int))
    => numeric(add, raw(col(duration)), stored(D))
  </k>
  [all-path]

  // CLAIM: LITERAL-PLUS-DURATION-FIELD
  // SPEC-PROVENANCE:
  // - E1: "durations-only expressions" covers reversed duration-only operands.
  // - E3: Both operands must remain stored microsecond values.
  claim <k>
    compileDurationExpression(add, durValue(D:Int), col(duration))
    => numeric(add, stored(D), raw(col(duration)))
  </k>
  [all-path]

  // CLAIM: DURATION-FIELD-PLUS-DURATION-FIELD
  // SPEC-PROVENANCE:
  // - E1: DurationField + DurationField is duration-only arithmetic.
  // - E3: Stored representation is integer microseconds.
  claim <k>
    compileDurationExpression(add, col(duration), col(duration))
    => numeric(add, raw(col(duration)), raw(col(duration)))
  </k>
  [all-path]

  // CLAIM: TEMPORAL-SUBTRACTION-PLUS-DURATION
  // SPEC-PROVENANCE:
  // - E5: Same-type temporal subtraction is duration-producing in Django.
  // - F2/PO3: V1 missed this case; V2 must classify it as duration-only.
  claim <k>
    compileDurationExpression(add, col(duration), bin(sub, col(datetime), col(datetime)))
    => numeric(add, raw(col(duration)), raw(bin(sub, col(datetime), col(datetime))))
  </k>
  [all-path]

  // CLAIM: MIXED-DATETIME-PLUS-DURATION
  // SPEC-PROVENANCE:
  // - E4: Mixed DateTime + DurationField must keep backend interval handling.
  claim <k>
    compileDurationExpression(add, col(datetime), col(duration))
    => durationFn(add, raw(col(datetime)), formatted(raw(col(duration))))
  </k>
  [all-path]

  // CLAIM: MULTIPLY-STAYS-ON-BACKEND-DURATION-PATH
  // SPEC-PROVENANCE:
  // - E6: This fix must not newly accept invalid duration operators.
  claim <k>
    compileDurationExpression(mul, col(duration), durValue(D:Int))
    => durationFn(mul, formatted(raw(col(duration))), interval(D))
  </k>
  [all-path]
endmodule

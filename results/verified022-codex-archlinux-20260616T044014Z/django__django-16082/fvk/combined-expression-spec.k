requires "mini-combined-expression.k"

module COMBINED-EXPRESSION-SPEC
  imports MINI-COMBINED-EXPRESSION

  // SPEC-PROVENANCE:
  // - from_prompt: "if the types of the query are different (Decimal and
  //   Integer), it doesn't resolve the result to a Decimal type" =>
  //   Decimal/Integer modulo must infer DecimalField.
  // - from_code: V1 adds mod to the mixed numeric connector list, whose
  //   IntegerField/DecimalField rows resolve to DecimalField.
  claim <k> resolve(mod, decimal, integer) => some(decimal) </k> [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "different (Decimal and Integer)" and expression operands
  //   can appear on either side of a connector => both operand orders are
  //   in-domain.
  // - from_code: the mixed numeric table contains both Decimal/Integer orders.
  claim <k> resolve(mod, integer, decimal) => some(decimal) </k> [all-path]

  // SPEC-PROVENANCE:
  // - from_code: _resolve_combined_type uses issubclass(), so IntegerField
  //   subclasses such as AutoField/BigIntegerField inherit the IntegerField row.
  // - from_prompt: "Integer" is a numeric field family, not only one exact
  //   class spelling.
  claim <k> resolve(mod, decimal, integerSub) => some(decimal) </k> [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "mixed numeric types" and "like other mathematical
  //   operators" => the whole existing mixed numeric table should receive MOD,
  //   not only one hand-coded Decimal/Integer row.
  // - from_code: the table's other mixed numeric rows map Integer/Float to
  //   Float, so V1 registers those rows for MOD as well.
  claim <k> resolve(mod, integer, float) => some(float) </k> [all-path]
  claim <k> resolve(mod, float, integer) => some(float) </k> [all-path]

  // SPEC-PROVENANCE:
  // - from_code: "Missing items will result in FieldError, by design." Mixed
  //   numeric POW was not part of the issue and is intentionally not added.
  claim <k> resolve(pow, decimal, integer) => noType </k> [all-path]
  claim <k> resolve(pow, integer, decimal) => noType </k> [all-path]
endmodule

requires "mini-up028-fix.k"

module UP028-FIX-SPEC
  imports MINI-UP028-FIX

  // SPEC-PROVENANCE:
  // - from_prompt: "Fixing yield-in-for-loop (UP028) fails ... when the iterable expression is an unparenthesized tuple."
  //   => a bare tuple iterable must not be emitted as a bare operand to `yield from`.
  // - from_prompt: example `for e in x,: yield e`
  //   => the singleton tuple source `x,` must become a parenthesized yield-from operand.
  // - from_code: V1 classifies `Expr::Tuple { parenthesized: false, .. }` as `bareTuple`.
  claim <k> fix(iter(bareTuple, "x,")) => "yield from (x,)" </k> [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "unparenthesized tuple" names the tuple source form, not only the literal identifier `x`.
  // - from_default_domain: in Python expression context, tuple syntax with commas is preserved by wrapping it in parentheses.
  // - from_code: V1 wraps the source slice for every unparenthesized tuple AST node.
  claim <k> fix(iter(bareTuple, S:String)) => ("yield from (" +String S) +String ")" </k> [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: the reported defect is specific to unparenthesized tuple iterables.
  // - from_code: V1 leaves all other sliced iterable text on the existing source-preserving path.
  claim <k> fix(iter(preserved, S:String)) => "yield from " +String S </k> [all-path]
endmodule

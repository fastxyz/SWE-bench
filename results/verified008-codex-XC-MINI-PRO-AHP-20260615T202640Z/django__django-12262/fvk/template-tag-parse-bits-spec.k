requires "mini-python.k"

module TEMPLATE-TAG-PARSE-BITS-SPEC
  imports MINI-PYTHON

  // SPEC-PROVENANCE:
  // - E1/E2/E5: keyword-only parameters, including those with defaults, are
  //   legal custom tag keywords.
  // - from_code: V1 checks legality against the complete kwonly list.
  // CLAIM: ALLOW-DEFAULT-KWONLY
  claim
    <k> parse(kw(P, V) .Bits) => done ... </k>
    <params> PARAMS </params>
    <kwonly> KWONLY </kwonly>
    <varkw> false </varkw>
    <kwargs> SEEN => add(P, SEEN) </kwargs>
    <requiredKwonly> .Names => .Names </requiredKwonly>
    <outcome> pending => ok </outcome>
    requires member(P, KWONLY)
     andBool notBool member(P, PARAMS)
     andBool notBool member(P, SEEN)
    [all-path]

  // SPEC-PROVENANCE:
  // - E3: duplicate keyword-only tokens must report "multiple values", not
  //   "unexpected keyword".
  // - from_code: V1 checks param in kwargs before unexpected-keyword validation.
  // CLAIM: DUPLICATE-KWONLY
  claim
    <k> parse(kw(P, V1) kw(P, V2) .Bits) => done ... </k>
    <params> PARAMS </params>
    <kwonly> KWONLY </kwonly>
    <varkw> false </varkw>
    <kwargs> .Names => add(P, .Names) </kwargs>
    <requiredKwonly> P , .Names => .Names </requiredKwonly>
    <outcome> pending => multiple(P) </outcome>
    requires member(P, KWONLY)
     andBool notBool member(P, PARAMS)
    [all-path]

  // SPEC-PROVENANCE:
  // - E6/E7: unknown keywords without **kwargs remain unexpected.
  // CLAIM: UNKNOWN-STILL-UNEXPECTED
  claim
    <k> parse(kw(P, V) .Bits) => done ... </k>
    <params> PARAMS </params>
    <kwonly> KWONLY </kwonly>
    <varkw> false </varkw>
    <kwargs> .Names => .Names </kwargs>
    <outcome> pending => unexpected(P) </outcome>
    requires notBool member(P, PARAMS)
     andBool notBool member(P, KWONLY)
    [all-path]

  // SPEC-PROVENANCE:
  // - E5/E7: required keyword-only parameters remain required.
  // CLAIM: MISSING-REQUIRED-KWONLY
  claim
    <k> parse(.Bits) => done ... </k>
    <requiredKwonly> P , .Names => P , .Names </requiredKwonly>
    <outcome> pending => missing(P , .Names) </outcome>
    [all-path]
endmodule

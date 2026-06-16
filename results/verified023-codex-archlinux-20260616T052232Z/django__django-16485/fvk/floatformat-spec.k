requires "mini-floatformat.k"

module FLOATFORMAT-SPEC
  imports MINI-FLOATFORMAT

  // SPEC-PROVENANCE:
  // - from_prompt: "floatformat() crashes on \"0.00\"" =>
  //   zero-valued finite decimals are in-domain and must not raise from
  //   decimal.Context precision construction.
  // - from_prompt: "floatformat('0.00', 0)" and
  //   "floatformat(Decimal('0.00'), 0)" =>
  //   precision argument 0 is in-domain for string and Decimal inputs.
  // - from_docs: passing 0 rounds to the nearest integer =>
  //   zero at precision 0 formats as "0".
  // - from_code: for zero decimals with exponent -S, the raw precision is
  //   P + 2 - S; V1 replaces it with max(1, P + 2 - S).
  claim
    <k> safePrec(P:Int, S:Int) => maxOne(rawPrecision(P, S)) </k>
    requires P >=Int 0 andBool S >=Int 0
    ensures maxOne(rawPrecision(P, S)) >=Int 1
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: the two reported calls use decimal scale S = 2 and P = 0.
  // - from_docs: precision 0 returns an integer-form string.
  // - from_default_domain: Decimal zero quantized with valid precision remains
  //   zero, and Django suppresses a negative sign for rounded zero.
  claim
    <k> floatformatZero(0, S:Int) => "0" </k>
    requires S >=Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs: negative precision omits decimal places when no decimal part
  //   needs display; this branch returns before Context precision is used.
  // - from_code: V1 does not alter the early p < 0 zero path.
  claim
    <k> floatformatZeroNegative(P:Int) => "0" </k>
    requires P <Int 0
    [all-path]
endmodule

requires "mini-numberformat.k"

module NUMBERFORMAT-SPEC
  imports MINI-NUMBERFORMAT

  // SPEC-PROVENANCE:
  // - from_prompt: "when a decimal_pos argument is supplied and the number to
  //   be formatted is smaller in absolute size than what can be encoded using
  //   the provided number of decimal positions, the returned string should be
  //   0.0000...000 instead" => nonzero tiny decimals reach FixedZero.
  // - from_prompt: nformat(Decimal('1e-200'), '.', decimal_pos=2) must not
  //   return '1.00e-200' => the concrete cutoff-triggering case reaches
  //   FixedZero(pos, 2).
  claim <k> formatDecimal(pos, false, -200, 1, 2, true)
        => FixedZero(pos, 2) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_default_domain: zero is exactly representable at every finite
  //   decimal_pos; with decimal_pos supplied, the fixed formatter pads zeros.
  // - from_finding: V1 did not cover zero-valued Decimals whose exponent still
  //   tripped the 200-digit cutoff.
  claim <k> formatDecimal(SIGN:Sign, true, EXP:Int, LEN:Int, N:Int, CUTOFF:Bool)
        => FixedZero(SIGN, N) </k>
    requires N >=Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: values smaller than the lowest displayable decimal position
  //   should render as fixed zeros when decimal_pos is supplied.
  // - from_code: Decimal.as_tuple() gives exponent and digit length; for a
  //   nonzero Decimal, adjusted exponent < -N is equivalent to
  //   exponent + len(digits) <= -N.
  claim <k> formatDecimal(SIGN:Sign, false, EXP:Int, LEN:Int, N:Int, CUTOFF:Bool)
        => FixedZero(SIGN, N) </k>
    requires N >=Int 0
     andBool EXP <Int 0
     andBool EXP +Int LEN <=Int 0 -Int N
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code/comment: the existing 200-digit cutoff intentionally keeps
  //   non-small large values in scientific notation to avoid high memory use.
  // - frame condition: V2 must not remove that protection.
  claim <k> formatDecimal(SIGN:Sign, false, EXP:Int, LEN:Int, N:Int, true)
        => Scientific </k>
    requires N >=Int 0
     andBool notBool (EXP <Int 0 andBool EXP +Int LEN <=Int 0 -Int N)
    [all-path]
endmodule

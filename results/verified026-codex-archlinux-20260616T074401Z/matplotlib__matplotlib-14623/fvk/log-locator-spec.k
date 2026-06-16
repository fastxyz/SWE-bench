requires "mini-python-log-limits.k"

module LOG-LOCATOR-SPEC
  imports MINI-PYTHON-LOG-LIMITS

  // SPEC-PROVENANCE:
  // - E1/E2/E3: The public issue requires set_ylim(high, low) to invert log
  //   axes for finite positive data.
  // - E4/E6: Matplotlib represents inversion by storing the view interval in
  //   reversed order.
  // - E7: Base locator nonsingular behavior preserves reversed order.
  claim
    <k> logNonsingular(HIGH:Int, LOW:Int, MINPOS:Int, true, true)
      => pair(HIGH, LOW) ... </k>
    requires HIGH >Int LOW andBool LOW >Int 0 andBool MINPOS >Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - E4/E5/E8: For positive limits, the log scale clamp is identity and the
  //   stored view interval determines axis inversion.
  claim
    <k> axisSetLogLimits(HIGH:Int, LOW:Int, MINPOS:Int)
      => pair(HIGH, LOW) ... </k>
    requires HIGH >Int LOW andBool LOW >Int 0 andBool MINPOS >Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - E6: Axis.get_inverted returns high < low on the stored interval.
  claim
    <k> isInverted(axisSetLogLimits(HIGH:Int, LOW:Int, MINPOS:Int))
      => true ... </k>
    requires HIGH >Int LOW andBool LOW >Int 0 andBool MINPOS >Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - E5/E7: Normal increasing limits must not be inverted by the fix.
  claim
    <k> logNonsingular(LOW:Int, HIGH:Int, MINPOS:Int, true, true)
      => pair(LOW, HIGH) ... </k>
    requires HIGH >Int LOW andBool LOW >Int 0 andBool MINPOS >Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - E8: Positive log-scale range limiting is an identity frame condition.
  claim
    <k> limitRangeForLog(pair(A:Int, B:Int), MINPOS:Int)
      => pair(A, B) ... </k>
    requires A >Int 0 andBool B >Int 0 andBool MINPOS >Int 0
    [all-path]
endmodule


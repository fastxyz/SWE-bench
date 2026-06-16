requires "mini-unsigned-coder.k"

module MINI-UNSIGNED-CODER-SPEC
  imports MINI-UNSIGNED-CODER
  imports INT
  imports BOOL
  imports LIST

  // SPEC-PROVENANCE:
  // - from_problem: "_Unsigned=False" on unsigned OPeNDAP bytes stores signed bytes.
  // - from_problem_example: unsigned byte 128/255 must become signed -128/-1.
  // - from_source: decode moves _Unsigned from attrs to encoding via pop_to.
  rule castValue(kindI, 1, V:Int) => V -Int 256
    requires V >=Int 128 andBool V <=Int 255 [simplification]
  rule castValue(kindI, 1, V:Int) => V
    requires V >=Int 0 andBool V <Int 128 [simplification]
  rule castValue(kindU, 1, V:Int) => V +Int 256
    requires V <Int 0 andBool V >=Int -128 [simplification]
  rule castValue(kindU, 1, V:Int) => V
    requires V >=Int 0 andBool V <=Int 127 [simplification]

  // SPEC-PROVENANCE:
  // - from_source: _Unsigned branch only runs if the attr is present.
  claim
    <k> decode => done </k>
    <kind> K:Kind </kind>
    <itemsize> W:Int </itemsize>
    <values> VS:List </values>
    <fill> F:MaybeInt </fill>
    <attrsUnsigned> mAbsent </attrsUnsigned>
    <encodingUnsigned> mAbsent </encodingUnsigned>
    <warnings> WS:Warns </warnings>
    requires W >Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - E1/E8: signed integer data plus _Unsigned="true" is decoded as unsigned.
  claim
    <k> decode => done </k>
    <kind> kindI => kindU </kind>
    <itemsize> W:Int </itemsize>
    <values> VS:List => castValues(kindU, W, VS) </values>
    <fill> F:MaybeInt => castFill(kindU, W, F) </fill>
    <attrsUnsigned> mTrueString => mAbsent </attrsUnsigned>
    <encodingUnsigned> _ => mTrueString </encodingUnsigned>
    <warnings> WS:Warns </warnings>
    requires W >Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - E3/E9: explicit boolean true is accepted for decode symmetry.
  claim
    <k> decode => done </k>
    <kind> kindI => kindU </kind>
    <itemsize> W:Int </itemsize>
    <values> VS:List => castValues(kindU, W, VS) </values>
    <fill> F:MaybeInt => castFill(kindU, W, F) </fill>
    <attrsUnsigned> mBoolTrue => mAbsent </attrsUnsigned>
    <encodingUnsigned> _ => mBoolTrue </encodingUnsigned>
    <warnings> WS:Warns </warnings>
    requires W >Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - E2/E4/E8: unsigned OPeNDAP bytes plus _Unsigned="false" are signed bytes.
  claim
    <k> decode => done </k>
    <kind> kindU => kindI </kind>
    <itemsize> W:Int </itemsize>
    <values> VS:List => castValues(kindI, W, VS) </values>
    <fill> F:MaybeInt => castFill(kindI, W, F) </fill>
    <attrsUnsigned> mFalseString => mAbsent </attrsUnsigned>
    <encodingUnsigned> _ => mFalseString </encodingUnsigned>
    <warnings> WS:Warns </warnings>
    requires W >Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - E3: issue explicitly sketches `unsigned == False`.
  claim
    <k> decode => done </k>
    <kind> kindU => kindI </kind>
    <itemsize> W:Int </itemsize>
    <values> VS:List => castValues(kindI, W, VS) </values>
    <fill> F:MaybeInt => castFill(kindI, W, F) </fill>
    <attrsUnsigned> mBoolFalse => mAbsent </attrsUnsigned>
    <encodingUnsigned> _ => mBoolFalse </encodingUnsigned>
    <warnings> WS:Warns </warnings>
    requires W >Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - E6: _Unsigned applies to integer arrays; no opposite signedness means no cast.
  claim
    <k> decode => done </k>
    <kind> K:Kind </kind>
    <itemsize> W:Int </itemsize>
    <values> VS:List </values>
    <fill> F:MaybeInt </fill>
    <attrsUnsigned> M:Marker => mAbsent </attrsUnsigned>
    <encodingUnsigned> _ => M </encodingUnsigned>
    <warnings> WS:Warns </warnings>
    requires W >Int 0
      andBool isIntegerKind(K)
      andBool notBool shouldConvert(M, K)
      andBool M =/=K mAbsent
    [all-path]

  // SPEC-PROVENANCE:
  // - E6/source behavior: non-integer data with _Unsigned warns and is not cast.
  claim
    <k> decode => done </k>
    <kind> kindOther </kind>
    <itemsize> W:Int </itemsize>
    <values> VS:List </values>
    <fill> F:MaybeInt </fill>
    <attrsUnsigned> M:Marker => mAbsent </attrsUnsigned>
    <encodingUnsigned> _ => M </encodingUnsigned>
    <warnings> WS:Warns => warnUnsignedNonInteger WS </warnings>
    requires W >Int 0 andBool M =/=K mAbsent
    [all-path]
endmodule

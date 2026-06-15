requires "mini-python-unit-eq.k"

module UNRECOGNIZED-UNIT-EQ-SPEC
  imports MINI-PYTHON-UNIT-EQ

  // SPEC-PROVENANCE:
  // - from_prompt: "x == None  # Should be False" => TypeError conversion
  //   failure from Unit(None) must not escape equality.
  // - from_prompt: "`==` should never fail" => known unit-conversion
  //   rejection failures in equality return False.
  claim <k> eqUnrecognized(S:String, raises(typeError)) => false </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: UnitBase.__eq__ catches ValueError, UnitsError, TypeError.
  // - from_prompt: "`==` should never fail" => the same known conversion
  //   failures are unequal, not exceptional, for UnrecognizedUnit equality.
  claim <k> eqUnrecognized(S:String, raises(valueError)) => false </k>
    [all-path]

  claim <k> eqUnrecognized(S:String, raises(unitsError)) => false </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_test: test_unknown_unit3 asserts two silently parsed
  //   unknown units with the same name compare equal.
  claim <k> eqUnrecognized(S:String, ok(unrec(T:String))) => true </k>
    requires S ==String T
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_test: test_unknown_unit3 asserts different unknown unit
  //   names compare unequal.
  claim <k> eqUnrecognized(S:String, ok(unrec(T:String))) => false </k>
    requires S =/=String T
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: previous UnrecognizedUnit equality only returns True when
  //   the converted object is another UnrecognizedUnit with the same name.
  // - from_compatibility: recognized UnitBase equality semantics are not
  //   changed by this issue.
  claim <k> eqUnrecognized(S:String, ok(recognized)) => false </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: __ne__ is defined as not (self == other), so it must be the
  //   complement of the equality contract for every conversion class.
  claim <k> neUnrecognized(S:String, raises(typeError)) => true </k>
    [all-path]
endmodule

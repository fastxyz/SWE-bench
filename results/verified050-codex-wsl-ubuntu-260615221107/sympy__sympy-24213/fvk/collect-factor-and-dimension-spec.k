requires "mini-unit-dimension.k"

module COLLECT-FACTOR-AND-DIMENSION-SPEC
  imports MINI-UNIT-DIMENSION

  // SPEC-PROVENANCE:
  // - from_prompt: "collect_factor_and_dimension does not detect equivalent
  //   dimensions in addition" => addition must accept addends whose dimensions
  //   are equivalent in the active dimension system.
  // - from_prompt: reported failure compares Dimension(velocity) with
  //   Dimension(acceleration*time) => velocity and acceleration*time are the
  //   concrete equivalent-dimension pair.
  // - from_code: accepted Add expressions sum collected factors and return the
  //   first addend's dimension expression.
  claim
    <k> collectAdd(fd(F1:Int, accelerationTime) ; fd(F2:Int, velocity) ; .FDList, withDimSystem)
        => ok(F1 +Int F2, accelerationTime)
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: the issue is about all equivalent dimensions in addition,
  //   not only the reproduced quantity names.
  // - from_code: equivalent_dims compares dependency maps in DimensionSystem.
  claim
    <k> collectAdd(fd(F:Int, D:Dim) ; REST:FDList, withDimSystem)
        => ok(F +Int sumFactors(REST), D)
    </k>
    requires allCompatible(withDimSystem, D, REST)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_public_tests: incompatible unit additions are expected to raise
  //   ValueError; the fix must preserve that error behavior.
  // - from_code: no-dimension-system unit systems have no dependency map, so
  //   direct dimension equality remains the compatibility predicate.
  claim
    <k> collectAdd(fd(F1:Int, length) ; fd(F2:Int, time) ; .FDList, withDimSystem)
        => dimensionError(time, length)
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: V1 explicitly falls back to direct equality when
  //   get_dimension_system() is None.
  claim
    <k> collectAdd(fd(F1:Int, accelerationTime) ; fd(F2:Int, velocity) ; .FDList, noDimSystem)
        => dimensionError(velocity, accelerationTime)
    </k>
    [all-path]
endmodule

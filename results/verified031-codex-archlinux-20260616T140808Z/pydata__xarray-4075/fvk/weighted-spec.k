requires "mini-weighted.k"

module MINI-WEIGHTED-SPEC
  imports MINI-WEIGHTED

  // SPEC-PROVENANCE:
  // - from_prompt: "convert it to int or float" for boolean weights.
  // - from_code: V1 casts the data operand only when both dtypes are boolean.
  // - obligation: the cast guard fires exactly on the bool/bool reducer path.
  claim <k> needsCast(boolKind, boolKind) => true </k> [all-path]

  // SPEC-PROVENANCE:
  // - from_code: V1 guard is conjunctive on both operand dtype kinds.
  // - obligation: mixed numeric/boolean paths keep the existing dot behavior.
  claim <k> needsCast(boolKind, otherKind) => false </k> [all-path]
  claim <k> needsCast(otherKind, boolKind) => false </k> [all-path]
  claim <k> needsCast(otherKind, otherKind) => false </k> [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: boolean denominator dot must produce numeric 2, not True.
  // - from_code: Weighted._reduce says it is equivalent to
  //   `(da * weights).sum(dim, skipna)`.
  // - obligation: bool/bool products reduce as an integer 0/1 dot product.
  claim <k> reduceBoolBool(BS:BList, WS:BList) => dot01(BS, WS) </k>
    requires sameLength(BS, WS)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: sum_of_weights is the normalization denominator.
  // - from_code: zero denominators are masked by `where(valid_weights)`.
  // - obligation: positive boolean-weight denominators are numeric counts.
  claim <k> sumOfWeightsBool(BS:BList, WS:BList)
        => SomeWeight(dot01(BS, WS)) </k>
    requires sameLength(BS, WS)
     andBool dot01(BS, WS) =/=Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: zero weights are invalid and become missing.
  // - obligation: the zero-denominator behavior is preserved.
  claim <k> sumOfWeightsBool(BS:BList, WS:BList) => NoWeight </k>
    requires sameLength(BS, WS)
     andBool dot01(BS, WS) ==Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: DataArray [1., 1., 1.] with boolean weights [1, 1, 0]
  //   should have weighted mean 1.0.
  // - derivation: numerator = 2, denominator = 2, so Ratio(2, 2) = 1.
  claim
    <k> weightedMeanBoolWeights(
          ICons(1, ICons(1, ICons(1, .IList))),
          BCons(true, BCons(true, BCons(true, .BList))),
          BCons(true, BCons(true, BCons(false, .BList))))
        => Ratio(2, 2)
    </k>
    [all-path]
endmodule

requires "mini-python-impute.k"

module ITERATIVE-IMPUTER-SPEC
  imports MINI-PYTHON-IMPUTE

  // SPEC-PROVENANCE:
  // - E-001: issue says IterativeImputer has no parameter fill_value.
  // - E-003: fill_value is the user-selected constant for initialization.
  // - from_code: V1 assigns self.fill_value = fill_value.
  claim <k> initIterative(F) => iterativeObj(F) ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E-002: initial_strategy is documented as SimpleImputer strategy.
  // - E-003: SimpleImputer.fill_value controls constant replacement.
  // - from_code: V1 passes fill_value=self.fill_value to SimpleImputer.
  claim <k> makeInitialImputer(S, F) => simpleObj(S, F) ... </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E-005: np.nan must be allowed as fill_value.
  // - from_code: V1 treats all features as valid when initial_strategy is constant.
  // - conflict avoided: non-V1 behavior would map all NaN statistics to no valid
  //   features, dropping every feature before a NaN-capable estimator can run.
  claim <k> validMask(constant, N, constantStats(N, NaNFill))
        => allIndices(N) ... </k>
    requires N >=Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - E-003: the constant strategy uses fill_value, not statistics validity, to
  //   decide feature preservation.
  claim <k> validMask(constant, N, STATS)
        => allIndices(N) ... </k>
    requires N >=Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - E-005 scope: the new np.nan handling is only required for the constant
  //   fill_value path.
  // - frame condition: non-constant strategies keep the previous non-NaN
  //   statistics filtering rule.
  claim <k> validMask(mean, N, STATS)
        => nonNanIndices(STATS, 0) ... </k>
    requires N >=Int 0
    [all-path]

  claim <k> validMask(median, N, STATS)
        => nonNanIndices(STATS, 0) ... </k>
    requires N >=Int 0
    [all-path]

  claim <k> validMask(most_frequent, N, STATS)
        => nonNanIndices(STATS, 0) ... </k>
    requires N >=Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - E-004: default behavior remains delegated to SimpleImputer by preserving
  //   NoneFill rather than replacing it in IterativeImputer.
  claim <k> initIterative(NoneFill) => iterativeObj(NoneFill) ... </k>
    [all-path]

  claim <k> makeInitialImputer(constant, NoneFill)
        => simpleObj(constant, NoneFill) ... </k>
    [all-path]
endmodule


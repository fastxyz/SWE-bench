requires "mini-python-repr.k"

module REPEATED-SPLITS-REPR-SPEC
  imports MINI-PYTHON-REPR

  // SPEC-PROVENANCE:
  // - E1/E3/E4: repeated splitters must not use object identity repr.
  // - E6: neighboring splitters delegate repr to _build_repr.
  claim
    <k> reprRepeated(obj("RepeatedKFold",
          key("n_repeats") key("n_splits") key("random_state") .Keys,
          pair("n_repeats", intVal(10))
          pair("random_state", noneVal)
          .Pairs,
          pair("n_splits", intVal(5)) .Pairs))
      => "RepeatedKFold(n_repeats=10, n_splits=5, random_state=None)" </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E1/E2/E5/E9: n_splits is a public constructor parameter stored in cvargs.
  claim
    <k> reprRepeated(obj("RepeatedStratifiedKFold",
          key("n_repeats") key("n_splits") key("random_state") .Keys,
          pair("n_repeats", intVal(10))
          pair("random_state", noneVal)
          .Pairs,
          pair("n_splits", intVal(5)) .Pairs))
      => "RepeatedStratifiedKFold(n_repeats=10, n_splits=5, random_state=None)" </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E6/E7/E8: existing direct-attribute behavior must be preserved.
  // - O3: direct attribute lookup takes precedence over cvargs fallback.
  claim
    <k> resolve("x",
          pair("x", noneVal) .Pairs,
          pair("x", intVal(7)) .Pairs)
      => noneVal </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E6: old _build_repr returned None for a missing direct attribute.
  // - O3: cvargs is only a fallback when it contains the missing parameter.
  claim
    <k> resolve("x", .Pairs, .Pairs) => noneVal </k>
    [all-path]
endmodule


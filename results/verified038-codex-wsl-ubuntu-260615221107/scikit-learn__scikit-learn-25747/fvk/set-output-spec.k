requires "mini-pandas-output.k"

module MINI-PANDAS-OUTPUT-SPEC
  imports MINI-PANDAS-OUTPUT

  // SPEC-PROVENANCE:
  // - from_prompt: "Expected Results: No error is thrown when using `pandas`
  //   transform output." => DataFrame output with fewer rows than the original
  //   input must not be forced onto the original input index.
  // - from_prompt_hint: "only set the index if it is not defined" and "If
  //   transformer returned a `DataFrame` this already has some kind of index"
  //   => an existing DataFrame index is preserved.
  // - from_code: _wrap_data_with_container passes original_input.index into
  //   _wrap_in_pandas_container; the helper decides whether to use it.
  claim
    <k> wrapData(
          pandasMode,
          true,
          df(payload(D:Id, OUTROWS:Int, OUTCOLS:Int), cols(OLD:Id, OUTCOLS), idx(OUTIDX:Id, OUTROWS)),
          idx(INIDX:Id, INROWS:Int),
          colCallableRaises
        )
        => df(payload(D, OUTROWS, OUTCOLS), cols(OLD, OUTCOLS), idx(OUTIDX, OUTROWS)) </k>
    requires OUTROWS >=Int 0
      andBool INROWS >=Int 0
      andBool OUTROWS =/=Int INROWS
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt_hint: existing DataFrame output has a defined index.
  // - from_docs: set_output uses get_feature_names_out for pandas columns.
  // - obligation: column names may be updated while the DataFrame index is
  //   preserved, even if the provided/original index has a different length.
  claim
    <k> wrapInPandas(
          df(payload(D:Id, OUTROWS:Int, OUTCOLS:Int), cols(OLD:Id, OUTCOLS), idx(OUTIDX:Id, OUTROWS)),
          colValue(cols(NEW:Id, OUTCOLS)),
          idx(INIDX:Id, INROWS:Int)
        )
        => df(payload(D, OUTROWS, OUTCOLS), cols(NEW, OUTCOLS), idx(OUTIDX, OUTROWS)) </k>
    requires OUTROWS >=Int 0
      andBool INROWS >=Int 0
      andBool OUTROWS =/=Int INROWS
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code/docstring: callable column-name errors have the same semantics
  //   as columns=None.
  // - obligation: when column-name resolution is unavailable, existing
  //   DataFrame columns and index are both preserved.
  claim
    <k> wrapInPandas(
          df(payload(D:Id, OUTROWS:Int, OUTCOLS:Int), cols(OLD:Id, OUTCOLS), idx(OUTIDX:Id, OUTROWS)),
          colCallableRaises,
          idx(INIDX:Id, INROWS:Int)
        )
        => df(payload(D, OUTROWS, OUTCOLS), cols(OLD, OUTCOLS), idx(OUTIDX, OUTROWS)) </k>
    requires OUTROWS >=Int 0
      andBool INROWS >=Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code/docstring: if data_to_wrap is not a DataFrame, a new DataFrame
  //   is created with the provided index.
  // - compatibility obligation: ordinary same-row transformer outputs keep
  //   their original input index when wrapped.
  claim
    <k> wrapInPandas(
          array(payload(D:Id, ROWS:Int, COLS:Int)),
          colValue(cols(NEW:Id, COLS)),
          idx(INIDX:Id, ROWS)
        )
        => df(payload(D, ROWS, COLS), cols(NEW, COLS), idx(INIDX, ROWS)) </k>
    requires ROWS >=Int 0
      andBool COLS >=Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code/docstring: "Pandas output does not support sparse data."
  // - obligation: sparse data is rejected before any DataFrame construction.
  claim
    <k> wrapInPandas(
          sparse(payload(D:Id, ROWS:Int, COLS:Int)),
          colValue(cols(NEW:Id, COLS)),
          idx(INIDX:Id, ROWS)
        )
        => sparseError </k>
    requires ROWS >=Int 0
      andBool COLS >=Int 0
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: default output or disabled auto-wrapping returns data_to_wrap
  //   unchanged.
  // - frame obligation: V1 does not alter default numpy/scipy behavior.
  claim
    <k> wrapData(defaultMode, true, OBJ:Obj, IDX:Index, COLS:ColArg)
        => OBJ </k>
    [all-path]

  claim
    <k> wrapData(pandasMode, false, OBJ:Obj, IDX:Index, COLS:ColArg)
        => OBJ </k>
    [all-path]
endmodule

requires "mini-python-indexing.k"

module PANDAS-MULTI-INDEXING-ADAPTER-SPEC
  imports MINI-PYTHON-INDEXING

  // SPEC-PROVENANCE:
  // - from_prompt: "Creating a MultiIndex should not change the data type of
  //   the Indexes from which it is built." => default conversion must preserve
  //   the original level coordinate dtype tracked by xarray.
  // - from_code: PandasMultiIndex.create_variables passes the level dtype into
  //   PandasMultiIndexingAdapter.
  // CLAIM-ID: MI-ARRAY-DEFAULT-LEVEL-DTYPE
  claim
    <k> __array__(
          adapter((LEVEL:String |-> values(PAYLOAD:String, PANDAS_DTYPE:DType)) LEVELS:Map,
                  STORED:DType,
                  someLevel(LEVEL)),
          noDType
        )
      => ndarray(values(PAYLOAD, STORED), STORED)
      ... </k>
    requires castable(values(PAYLOAD, PANDAS_DTYPE), STORED)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_default_domain: NumPy's __array__(dtype=...) protocol uses the
  //   explicitly requested dtype when supplied.
  // - from_code: V1 only substitutes self.dtype when dtype is None.
  // CLAIM-ID: MI-ARRAY-EXPLICIT-DTYPE
  claim
    <k> __array__(
          adapter((LEVEL:String |-> values(PAYLOAD:String, PANDAS_DTYPE:DType)) LEVELS:Map,
                  STORED:DType,
                  someLevel(LEVEL)),
          someDType(REQUESTED:DType)
        )
      => ndarray(values(PAYLOAD, REQUESTED), REQUESTED)
      ... </k>
    requires castable(values(PAYLOAD, PANDAS_DTYPE), REQUESTED)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: the issue's int32 example expects
  //   ds.stack(...)[level].values.dtype == original dtype.
  // - from_code: the adapter dtype equals the original coordinate dtype for
  //   level coordinates created by PandasMultiIndex.create_variables.
  // CLAIM-ID: STACKED-LEVEL-VALUES-DTYPE
  claim
    <k> __array__(
          adapter((LEVEL:String |-> values(PAYLOAD:String, PANDAS_DTYPE:DType)) LEVELS:Map,
                  ORIGINAL_DTYPE:DType,
                  someLevel(LEVEL)),
          noDType
        )
      => ndarray(values(PAYLOAD, ORIGINAL_DTYPE), ORIGINAL_DTYPE)
      ... </k>
    requires castable(values(PAYLOAD, PANDAS_DTYPE), ORIGINAL_DTYPE)
    [all-path]

  // SPEC-PROVENANCE:
  // - from_code: the V1 patch keeps the level is None branch delegated to
  //   PandasIndexingAdapter.__array__.
  // - from_compatibility_audit: method signature and result shape remain stable.
  // CLAIM-ID: MI-ARRAY-NONLEVEL-DELEGATES
  claim
    <k> __array__(adapter(LEVELS:Map, STORED:DType, noLevel), REQ:MaybeDType)
      => baseArray(adapter(LEVELS, STORED, noLevel), REQ)
      ... </k>
    [all-path]
endmodule

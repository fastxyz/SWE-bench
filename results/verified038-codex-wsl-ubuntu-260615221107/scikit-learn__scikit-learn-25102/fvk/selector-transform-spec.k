requires "mini-python.k"

module SELECTOR-TRANSFORM-SPEC
  imports MINI-PYTHON-SELECTOR
  imports BOOL

  // SPEC-PROVENANCE:
  // - E7: Existing set_output config controls whether pandas wrapping is used.
  // - E5: No generic dtype cast-back is specified.
  // - code fact: non-pandas/default paths call _validate_data and select from validated data.
  claim <k> transform(df(I:Index, C:Cols, D:DTypes, V:Values), M:Mask, default, AUTO:Bool)
           => selectArray(array(I, 0, homogeneous, V), M) ... </k>
    requires validForSelector(df(I, C, D, V)) andBool anySelected(M)
    [all-path]

  // SPEC-PROVENANCE:
  // - E7: Existing set_output config controls whether pandas wrapping is used.
  // - code fact: validated dense array inputs remain dense arrays for selected-column output.
  claim <k> transform(array(I:Index, N:Int, D:DType, V:Values), M:Mask, default, AUTO:Bool)
           => selectArray(array(I, N, D, V), M) ... </k>
    requires validForSelector(array(I, N, D, V)) andBool anySelected(M)
    [all-path]

  // SPEC-PROVENANCE:
  // - E7: Existing set_output config controls whether pandas wrapping is used.
  // - code fact: validated sparse inputs remain sparse for selected-column output.
  claim <k> transform(sparse(I:Index, N:Int, D:DType, V:Values), M:Mask, default, AUTO:Bool)
           => selectArray(sparse(I, N, D, V), M) ... </k>
    requires validForSelector(sparse(I, N, D, V)) andBool anySelected(M)
    [all-path]

  // SPEC-PROVENANCE:
  // - E1/E2/E3: pandas output for mixed-dtype SelectKBest should preserve selected input dtypes.
  // - E4: feature selectors may compute support using arrays and then select original container columns.
  // - E6: SelectorMixin returns a subset of input features.
  claim <k> transform(df(I:Index, cols(CS:List), dtypes(DS:List), values(VS:List)),
                      M:Mask, pandas, true)
           => df(I, cols(selectList(CS, M)), dtypes(selectList(DS, M)),
                 values(selectList(VS, M))) ... </k>
    requires validForSelector(df(I, cols(CS), dtypes(DS), values(VS)))
             andBool anySelected(M)
    [all-path]

  // SPEC-PROVENANCE:
  // - E6: empty support is a selector boundary case.
  // - code fact: existing behavior warns and returns zero selected features.
  claim <k> transform(df(I:Index, C:Cols, D:DTypes, V:Values), M:Mask, pandas, true)
           => emptyDataFrame(df(I, C, D, V), M) ... </k>
    requires validForSelector(df(I, C, D, V)) andBool notBool anySelected(M)
    [all-path]

  // SPEC-PROVENANCE:
  // - E5/E7: outside the original DataFrame pandas path, do not introduce cast-back behavior.
  claim <k> transform(array(I:Index, N:Int, D:DType, V:Values), M:Mask, C:Config, AUTO:Bool)
           => emptyArray(array(I, N, D, V)) ... </k>
    requires validForSelector(array(I, N, D, V))
             andBool notBool (isDataFrame(array(I, N, D, V)) andBool configIsPandas(C) andBool AUTO)
             andBool notBool anySelected(M)
    [all-path]

  // SPEC-PROVENANCE:
  // - F2: V1 read output config before validation; V2 preserves validation/raw-transform precedence.
  // - code fact: invalid config is treated as not pandas-preserving in _is_pandas_output_configured.
  claim <k> transform(df(I:Index, C:Cols, D:DTypes, V:Values), M:Mask, invalid, true)
           => selectArray(array(I, 0, homogeneous, V), M) ... </k>
    requires validForSelector(df(I, C, D, V)) andBool anySelected(M)
    [all-path]
endmodule

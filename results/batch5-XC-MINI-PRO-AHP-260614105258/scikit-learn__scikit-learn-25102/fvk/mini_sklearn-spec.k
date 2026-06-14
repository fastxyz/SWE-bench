// mini_sklearn-spec.k — reachability claims (function contracts) and the
// list-recursion circularity for the SelectorMixin dtype-preservation fix.
//
// CONSTRUCTED, NOT MACHINE-CHECKED.  Discharge later with:
//     kompile mini_sklearn.k --backend haskell
//     kprove  mini_sklearn-spec.k                  # expected: #Top
//
// Math (capital) variables are logical; program containers are lowercase tokens.

requires "mini_sklearn.k"

module MINI-SKLEARN-SPEC-SYNTAX
  imports MINI-SKLEARN-SYNTAX
endmodule

module VERIFICATION
  imports MINI-SKLEARN-SPEC-SYNTAX
  imports MINI-SKLEARN
  imports K-EQUAL
endmodule

module MINI-SKLEARN-SPEC
  imports VERIFICATION

  // ======================================================================
  // (SELECT-FRAME) — the heart: column subselection keeps survivors VERBATIM.
  // This is the circularity: list recursion on Cs.  Its postcondition is a
  // FRAME condition — every kept Col (hence its dtype) is unchanged.
  //
  // SPEC-PROVENANCE:
  // - from_prompt: "preserve the dtype ... I.e. doing the computation using a
  //   NumPy array, then creating the DataFrame and reassigning the dtypes" /
  //   "select the columns on the original container before the conversion"
  //   => surviving columns must be the ORIGINAL columns (dtype intact).
  // - from_code: SelectorMixin._transform returns _safe_indexing(X, mask, axis=1).
  // ======================================================================
  claim <k> selectCols(CS:List, MS:List) => selectColsSpec(CS, MS) ... </k>
    requires size(CS) ==Int size(MS)
    [all-path]

  // dtypesOf distributes over a verbatim subselection:
  // (DTYPE-FRAME) dtypesOf(df(selectCols(CS,MS))) == selectCols(dtypesOf(df(CS)), MS)
  // i.e. each selected column reports its ORIGINAL dtype.
  claim <k> dtypesOf(df(selectCols(CS:List, MS:List)))
         => selectCols(dtypesOf(df(CS)), MS) ... </k>
    requires size(CS) ==Int size(MS)
    [all-path]

  // ======================================================================
  // (TRANSFORM-PRESERVE) — pandas output + DataFrame input ⇒ DataFrame out,
  // built from the ORIGINAL columns (so every surviving dtype is preserved).
  //
  // SPEC-PROVENANCE:
  // - from_prompt: "It would be nice to optionally preserve the dtypes of the
  //   input using pandas output for transformers" / category & np.float16 must
  //   not become float64.
  // - from_code: preserve_X = (config != "default") and _is_pandas_df(X);
  //   _validate_data(..., cast_to_ndarray=not preserve_X).
  // ======================================================================
  claim <k> xform(df(CS:List), pandas, MS:List) => df(selectCols(CS, MS)) ... </k>
    [all-path]

  // ======================================================================
  // (TRANSFORM-DEFAULT) — default output ⇒ legacy homogeneous ndarray result.
  // Backward-compatibility frame condition: identical to the V0 numpy path.
  //
  // SPEC-PROVENANCE:
  // - from_prompt (maintainer): heterogeneous dtypes are intentionally NOT
  //   preserved in the default/legacy path; "all operations are done with NumPy
  //   arrays under the hood, inhomogeneous types will be converted to a single
  //   homogeneous type".
  // - from_code: preserve_X is False ⇒ cast_to_ndarray=True ⇒ check_array cast.
  // ======================================================================
  claim <k> xform(df(CS:List), default, MS:List)
         => arr(commonDtype(CS), selectCols(CS, MS)) ... </k>
    [all-path]

  // ======================================================================
  // (TRANSFORM-NONDF) — non-DataFrame input ⇒ legacy ndarray result for ANY
  // config (preserve_X is False because _is_pandas_df(arr)=false).  No
  // regression for numpy/sparse input under pandas output.
  //
  // SPEC-PROVENANCE:
  // - from_code: _is_pandas_df returns False for ndarray ⇒ preserve_X False ⇒
  //   cast_to_ndarray=True; toNdarray(arr) is the identity.
  // ======================================================================
  claim <k> xform(arr(D:Dtype, CS:List), CFG:Config, MS:List)
         => arr(D, selectCols(CS, MS)) ... </k>
    [all-path]

  // ----------------------------------------------------------------------
  // Spec-only helper used as the SELECT-FRAME postcondition: the masked
  // sublist, defined by the same recursion the claim discharges.
  syntax List ::= selectColsSpec(List, List) [function]
  rule selectColsSpec(.List, _) => .List
  rule selectColsSpec(_, .List) => .List
  rule selectColsSpec(ListItem(C) Cs, ListItem(true)  Ms) => ListItem(C) selectColsSpec(Cs, Ms)
  rule selectColsSpec(ListItem(_) Cs, ListItem(false) Ms) => selectColsSpec(Cs, Ms)
endmodule

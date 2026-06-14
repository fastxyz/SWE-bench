// mini_sklearn.k — a "mini-X" K fragment modeling exactly the constructs that
// SelectorMixin.transform / _transform / _validate_data(cast_to_ndarray=...) and
// _safe_indexing(..., axis=1) use to implement DataFrame-dtype preservation.
//
// CONSTRUCTED, NOT MACHINE-CHECKED (FVK MVP: we build the semantics + claims and
// emit the kompile/kprove commands; we do not run the toolchain here — there is no
// execution environment).
//
// SCOPE / FAITHFULNESS NOTE.  The real Python operates on heterogeneous pandas /
// numpy / scipy containers.  We model only the property under audit — *per-column
// dtype* and *which columns survive selection* — and abstract away the actual
// numeric values (an opaque ValsId) and the homogenizing arithmetic of
// check_array.  The one fact we DO encode about numpy conversion is the property
// that matters: an ndarray collapses every column to ONE shared dtype (dtype
// loss), whereas a DataFrame keeps each column's own dtype.

module MINI-SKLEARN-SYNTAX
  imports BOOL-SYNTAX
  imports INT-SYNTAX
  imports STRING-SYNTAX
  imports LIST

  // A dtype is an opaque token, e.g. "float16", "category", "float64".
  syntax Dtype ::= String

  // A column carries a name, its own dtype, and an opaque value-vector id.
  syntax Col ::= col(String, Dtype, Int)

  // Containers:
  //   df(Cols)         a pandas DataFrame  — each column keeps its OWN dtype
  //   arr(Dtype, Cols) a numpy ndarray     — ALL columns share ONE dtype
  // (Cols is a List of Col.)
  syntax Container ::= df(List)
                     | arr(Dtype, List)

  // set_output / global transform_output config value.
  syntax Config ::= "default" | "pandas"

  // Functions that model the implementation.
  syntax Bool      ::= isDf(Container)                  [function, total]
  syntax List      ::= dtypesOf(Container)              [function, total]
  syntax List      ::= selectCols(List, List)           [function]
  syntax Dtype     ::= commonDtype(List)                [function, total]
  syntax Container ::= toNdarray(Container)             [function, total]
  syntax Container ::= validate(Container, Bool)        [function, total]
  syntax Container ::= safeIndex1(Container, List)      [function]
  syntax Container ::= xform(Container, Config, List)   [function]
endmodule

module MINI-SKLEARN
  imports MINI-SKLEARN-SYNTAX

  // ---- isDf : models _is_pandas_df(X) (true only for df(_)) ----------------
  rule isDf(df(_))     => true
  rule isDf(arr(_, _)) => false

  // ---- dtypesOf : the per-column dtype list -------------------------------
  // DataFrame: each column reports its own dtype.
  rule dtypesOf(df(.List)) => .List
  rule dtypesOf(df(ListItem(col(_, D, _)) Rest)) => ListItem(D) dtypesOf(df(Rest))
  // ndarray: EVERY column reports the single shared dtype (this is the dtype loss).
  rule dtypesOf(arr(_, .List)) => .List
  rule dtypesOf(arr(D, ListItem(col(_, _, _)) Rest)) => ListItem(D) dtypesOf(arr(D, Rest))

  // ---- selectCols : keep Cols[i] VERBATIM where Mask[i] == true ------------
  // This is the abstraction of _safe_indexing's column subselection; keeping each
  // surviving Col unchanged is exactly "the dtype is preserved".
  rule selectCols(.List, _) => .List
  rule selectCols(_, .List) => .List
  rule selectCols(ListItem(C) Cs, ListItem(true)  Ms) => ListItem(C) selectCols(Cs, Ms)
  rule selectCols(ListItem(_) Cs, ListItem(false) Ms) => selectCols(Cs, Ms)

  // ---- toNdarray : models check_array's homogenizing conversion -----------
  // A DataFrame collapses to one common dtype; an ndarray is unchanged.
  rule toNdarray(df(Cs))     => arr(commonDtype(Cs), Cs)
  rule toNdarray(arr(D, Cs)) => arr(D, Cs)

  // ---- validate : models _validate_data(X, cast_to_ndarray=Cast) ----------
  // The NEW behavior under audit: Cast=false returns X unchanged (no conversion);
  // Cast=true performs the ndarray conversion (legacy path).
  rule validate(X, true)  => toNdarray(X)
  rule validate(X, false) => X

  // ---- safeIndex1 : models _safe_indexing(X, Mask, axis=1) ----------------
  // Column subselection that preserves the container kind (df stays df, arr stays
  // arr).  Verified equivalent to the legacy X[:, safe_mask(X, mask)] for arr/sparse
  // by the existing test test_safe_indexing_2d_mask (see FINDINGS F1).
  rule safeIndex1(df(Cs), M)     => df(selectCols(Cs, M))
  rule safeIndex1(arr(D, Cs), M) => arr(D, selectCols(Cs, M))

  // ---- xform : SelectorMixin.transform ∘ _transform (mask non-empty, ------
  //              length matched — the main return branch) -------------------
  //   preserve = (Config =/= "default") andBool _is_pandas_df(X)
  //   X        = _validate_data(X, cast_to_ndarray = notBool preserve)
  //   return     _safe_indexing(X, mask, axis=1)
  rule xform(X, Cfg, M)
    => safeIndex1(validate(X, notBool ((Cfg =/=K default) andBool isDf(X))), M)
endmodule

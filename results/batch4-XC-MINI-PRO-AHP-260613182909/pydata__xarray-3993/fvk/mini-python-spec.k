// =====================================================================
//  fvk/mini-python-spec.k
//  Reachability claims for the argument-resolution contract of
//  DataArray.integrate (pydata/xarray #3993 V1 fix).
//
//  Status: CONSTRUCTED, NOT MACHINE-CHECKED (FVK MVP).
//
//  The changed code has NO loop, so there is NO circularity to discharge:
//  the contract is a finite 4-case DECISION TABLE over the input domain
//  (coord in {None, present}) x (dim in {None, present}), proved by direct
//  exhaustive symbolic execution (Case Analysis + Axiom + Transitivity).
//  The only loop in the integrate machinery lives in the UNCHANGED
//  Dataset.integrate (`for c in coord`) and is abstracted as the trusted
//  opaque `dset(coord, unit)` (FINDINGS F-6 / PROOF_OBLIGATIONS PO-7).
// =====================================================================

requires "mini-python.k"

module MINI-PYTHON-SPEC-SYNTAX
  imports MINI-PYTHON-SYNTAX

  // The body of DataArray.integrate after the V1 fix, transcribed into the
  // fragment. `coord`, `dim`, `ds`, `result`, `datetimeUnit` are program
  // variables (Ids); `datetimeUnit` stands for the Python `datetime_unit`.
  syntax Stmt ::= "integrateBody"  [macro]
  rule integrateBody =>
         if (dim isNotNone) and (coord isNotNone)
            then { raiseValueError("Cannot pass both 'dim' and 'coord'. Please pass only 'coord' instead.") }
         if (dim isNotNone) and (coord isNone)
            then { coord = dim   warn() }
         ds = dsetIntegrate(coord, datetimeUnit)
         result = fromTemp(ds)
         return result
endmodule

module VERIFICATION
  imports MINI-PYTHON-SPEC-SYNTAX
  imports MINI-PYTHON
  imports MAP-SYMBOLIC
  imports K-EQUAL
  // No [simplification] lemmas are needed: there is no nonlinear arithmetic,
  // and the postcondition pins <out>/<warned>, not a symbolic store binding,
  // so no map-extensionality / exact-halving lemma is required.
endmodule

module MINI-PYTHON-SPEC
  imports VERIFICATION

  // (R1) NEW-STYLE  -- integrate(coord = present, dim = None)
  //   => forward coord to the delegate; NO warning.
  claim <k> integrateBody => .K </k>
        <store> coord |-> tok(CI:Int)  datetimeUnit |-> U:Val  dim |-> None
                  => ?_:Map </store>
        <warned> false => false </warned>
        <out>    .K    => daOf(dset(tok(CI), U)) </out>
        [all-path]

  // (R2) DEPRECATED  -- integrate(coord = None, dim = present)
  //   => forward dim as the coordinate; emit the FutureWarning.
  claim <k> integrateBody => .K </k>
        <store> coord |-> None  datetimeUnit |-> U:Val  dim |-> tok(DI:Int)
                  => ?_:Map </store>
        <warned> false => true </warned>
        <out>    .K    => daOf(dset(tok(DI), U)) </out>
        [all-path]

  // (R3) CONFLICT  -- integrate(coord = present, dim = present)
  //   => ValueError; delegate NOT called; NO warning.
  claim <k> integrateBody => .K </k>
        <store> coord |-> tok(CI:Int)  datetimeUnit |-> U:Val  dim |-> tok(DI:Int)
                  => ?_:Map </store>
        <warned> false => false </warned>
        <out>    .K    => raised("Cannot pass both 'dim' and 'coord'. Please pass only 'coord' instead.") </out>
        [all-path]

  // (R4) DEGENERATE  -- integrate(coord = None, dim = None)
  //   => forward None to the delegate; NO warning.
  //   The UNCHANGED delegate then raises ValueError("Coordinate None does not
  //   exist.") at runtime; modeling that internal raise is an escalation
  //   boundary (exception propagation out of the fragment) -- see
  //   FINDINGS F-5 and PROOF_OBLIGATIONS PO-6 / PO-7.
  claim <k> integrateBody => .K </k>
        <store> coord |-> None  datetimeUnit |-> U:Val  dim |-> None
                  => ?_:Map </store>
        <warned> false => false </warned>
        <out>    .K    => daOf(dset(None, U)) </out>
        [all-path]
endmodule

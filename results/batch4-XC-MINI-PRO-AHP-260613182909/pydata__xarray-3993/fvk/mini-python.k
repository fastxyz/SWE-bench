// =====================================================================
//  fvk/mini-python.k
//  Mini-Python fragment semantics for the ARGUMENT-RESOLUTION logic of
//  DataArray.integrate, as changed by the pydata/xarray #3993 fix (V1).
//
//  Status: CONSTRUCTED, NOT MACHINE-CHECKED (FVK MVP). We do not run
//  kompile / kprove; the run-commands are emitted in fvk/PROOF.md.
//
//  Scope. We model ONLY the constructs the *changed* code uses:
//    - the None literal and `is None` / `is not None` identity tests
//    - short-circuiting boolean `and`
//    - single-branch `if`
//    - assignment
//    - `raise ValueError(<msg>)`        (the conflict guard the fix added)
//    - `warnings.warn(..., FutureWarning, ...)`  (modeled as a one-bit flag)
//    - `return`
//    - three OPAQUE delegate calls the fix does NOT change:
//        self._to_temp_dataset()        -> toTemp()
//        <temp>.integrate(coord, unit)  -> dsetIntegrate(coord, unit)
//        self._from_temp_dataset(ds)    -> fromTemp(ds)
//
//  The numerical work (the trapezoidal rule, the `for c in coord` loop in
//  the UNCHANGED Dataset.integrate / _integrate_one) is abstracted into the
//  opaque constructor `dset(coord, unit)`: the fix only RESOLVES which
//  coordinate to forward; it does not alter the computation. See SPEC.md and
//  FINDINGS F-6 (escalation boundary) for why this abstraction is faithful.
// =====================================================================

module MINI-PYTHON-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports ID-SYNTAX
  imports STRING-SYNTAX

  // Program values. An argument is either Python None, or an opaque
  // "present" token tok(_) standing for ANY non-None coordinate name,
  // sequence of names, or datetime_unit. The fix never inspects a token's
  // structure -- it only ever asks "None or not" -- so this is faithful,
  // and crucially tok(_) also covers FALSY-but-valid names (0, "", False):
  // the code uses `is not None`, not truthiness. (See FINDINGS F-3.)
  syntax Val ::= "None"
               | "tok" "(" Int ")"
               | "tempOf" "(" ")"            // value of self._to_temp_dataset()
               | "dset" "(" Val "," Val ")"  // value of <temp>.integrate(coord,unit)
               | "daOf" "(" Val ")"          // value of self._from_temp_dataset(ds)

  syntax Exp ::= Val | Id
               | "(" Exp ")"                           [bracket]
               | "toTemp" "(" ")"
               | "dsetIntegrate" "(" Exp "," Exp ")"   [seqstrict]
               | "fromTemp" "(" Exp ")"                [strict]
               > Exp "isNotNone"                       [strict]
               | Exp "isNone"                          [strict]
               > Exp "and" Exp                         [strict(1), left]

  syntax Stmt ::= Id "=" Exp                       [strict(2)]
                | "if" Exp "then" "{" Stmt "}"      [strict(1)]
                | "raiseValueError" "(" String ")"
                | "warn" "(" ")"
                | "return" Exp                      [strict]
                > Stmt Stmt                         [left]

  syntax KResult ::= Val | Bool
endmodule

module MINI-PYTHON
  imports MINI-PYTHON-SYNTAX
  imports INT
  imports BOOL

  configuration
    <k>      $PGM:Stmt </k>
    <store>  $IN:Map   </store>    // coord |-> Val, datetimeUnit |-> Val, dim |-> Val, ...
    <warned> false     </warned>   // becomes true iff warnings.warn() executed
    <out>    .K        </out>      // the returned value, or raised(<msg>)

  syntax KItem ::= "raised" "(" String ")"

  // ---- variable lookup --------------------------------------------------
  rule <k> X:Id => V ... </k> <store> ... X |-> V ... </store>

  // ---- None identity tests ---------------------------------------------
  rule <k> None   isNotNone => false ... </k>
  rule <k> tok(_) isNotNone => true  ... </k>
  rule <k> None   isNone    => true  ... </k>
  rule <k> tok(_) isNone    => false ... </k>

  // ---- short-circuiting boolean and (Python semantics) -----------------
  rule <k> true  and E:Exp => E     ... </k>
  rule <k> false and _:Exp => false ... </k>

  // ---- opaque delegates (UNCHANGED code, abstracted; see FINDINGS F-6) -
  rule <k> toTemp()                    => tempOf()  ... </k>
  rule <k> dsetIntegrate(C:Val, U:Val) => dset(C, U) ... </k>
  rule <k> fromTemp(D:Val)             => daOf(D)   ... </k>

  // ---- assignment -------------------------------------------------------
  rule <k> X:Id = V:Val => .K ... </k>
       <store> STORE => STORE [ X <- V ] </store>

  // ---- single-branch if (braces stand in for Python's indented suite) --
  rule <k> if true  then { S:Stmt } => S  ... </k>
  rule <k> if false then { _:Stmt } => .K ... </k>

  // ---- statement sequencing --------------------------------------------
  rule <k> S1:Stmt S2:Stmt => S1 ~> S2 ... </k>

  // ---- warnings.warn : set the one-bit flag ----------------------------
  rule <k> warn() => .K ... </k> <warned> _ => true </warned>

  // ---- raise : abort, discarding the rest of the computation -----------
  //  We deliberately do NOT model Python exception propagation (escalation,
  //  out of fragment). Reaching <out> = raised(M) with <k> = .K, the delegate
  //  never evaluated and <warned> = false, faithfully captures "the function
  //  raised and neither warned nor delegated".
  rule <k> raiseValueError(M:String) ~> _REST => .K </k>
       <out> _ => raised(M) </out>

  // ---- return : deliver the value --------------------------------------
  rule <k> return V:Val ~> _REST => .K </k>
       <out> _ => V </out>
endmodule

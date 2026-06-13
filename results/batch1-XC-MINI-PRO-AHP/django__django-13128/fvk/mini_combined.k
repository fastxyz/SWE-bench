// mini_combined.k
// =====================================================================
// A minimal K ("mini-X") fragment modelling the *type-level* control flow
// of the V1 fix:
//
//     CombinedExpression._resolve_output_field(self)
//         django/db/models/expressions.py  (lines 445-458)
//
// and the unchanged base method it falls back to:
//
//     BaseExpression._resolve_output_field(self)   (lines 287-312)
//
// ABSTRACTION (faithful to what the method actually inspects):
//   * A Field instance is abstracted to the *string returned by*
//     get_internal_type() — that name is the ONLY property of a field this
//     method reads.  Tokens: DateField / DateTimeField / TimeField (the
//     three temporal types), DurationField, and `Other` (any other single
//     resolvable type such as IntegerField).
//   * `none`  models a source whose `_output_field_or_none` is Python None
//     (an unresolvable-to-None source).
//   * `mixed` is a sentinel *result* meaning "the base method raised
//     FieldError('... mixed types ...')".  We model the raise as a value so
//     the in-domain body stays total (FVK: model the reduced in-domain body,
//     turn raises into Findings — see FINDINGS F3/F4).
//   * `baseVal(L,R)` is a SPEC-ONLY uninterpreted function standing for "the
//     result of the UNCHANGED base method on sources (L,R)".  The fix returns
//     it verbatim on every non-temporal-subtraction input, so the proof of
//     regression-freedom never needs its concrete value — except the one
//     fact `baseVal(F,F) = F`, which holds because isinstance(x, type(x)) is
//     always True (two identical internal types are always compatible).
//
// Constructed, NOT machine-checked: no K toolchain runs in this environment.
// =====================================================================

module MINI-COMBINED-SYNTAX
  imports BOOL-SYNTAX

  // ---- abstract field-type values -----------------------------------
  syntax Field ::= "DateField" | "DateTimeField" | "TimeField"   // temporal
                 | "DurationField"
                 | "Other"     // any other single resolvable type
                 | "none"      // Python None  (source._output_field_or_none is None)
                 | "mixed"     // sentinel: base resolution raised FieldError

  // ---- the binary connector (only SUB is special) -------------------
  syntax Conn ::= "SUB"        // self.SUB  ('-')
                | "ADD"        // stands for EVERY non-SUB connector

  // ---- expression forms the method body uses ------------------------
  syntax Exp ::= Field | Bool | Conn
               | "connector"                  // self.connector
               | "lhsField" | "rhsField"      // get_source_fields()[0], [1]
               | "base"                       // super()._resolve_output_field()
               | "itype" "(" Exp ")"   [strict]   // x.get_internal_type()
               | "temporalSet" "(" Exp ")" [strict] // x in {DateField,DateTimeField,TimeField}
               | "notNone" "(" Exp ")" [strict]   // x is not None
               > Exp "eq" Exp   [seqstrict]   // Python ==
               > Exp "and" Exp  [seqstrict]   // Python and

  syntax Stmt ::= "resolve"                   // the method body, named
                | "if" Exp "then" Stmt "else" Stmt
                | "return" Exp

  syntax KResult ::= Field | Bool | Conn
endmodule

module MINI-COMBINED
  imports MINI-COMBINED-SYNTAX
  imports BOOL
  imports K-EQUAL

  configuration
    <k> $PGM:Stmt </k>
    <conn> ADD:Conn  </conn>    // self.connector
    <lhs>  none:Field </lhs>    // get_source_fields()[0]
    <rhs>  none:Field </rhs>    // get_source_fields()[1]
    <out>  .K        </out>     // the returned Field

  // ---- the method body (nested ifs, faithful to lines 451-458) ------
  // Note the NESTED structure: get_internal_type()/itype is reached ONLY
  // after the `is not None` guard, exactly as in the source.  This is what
  // makes itype(none) unreachable (it has no rule), modelling Python's
  // short-circuit through the nesting rather than through `and`.
  rule <k> resolve =>
            if connector eq SUB
            then ( if notNone(lhsField) and notNone(rhsField)
                   then ( if temporalSet(itype(lhsField)) and (itype(lhsField) eq itype(rhsField))
                          then return DurationField           // THE FIX
                          else return base )
                   else return base )
            else return base
       ... </k>

  // ---- reads --------------------------------------------------------
  rule <k> connector => C ... </k> <conn> C </conn>
  rule <k> lhsField  => L ... </k> <lhs>  L </lhs>
  rule <k> rhsField  => R ... </k> <rhs>  R </rhs>

  // ---- get_internal_type(): identity on the abstracted names --------
  // Defined for every concrete field; deliberately UNDEFINED for `none`
  // and `mixed` (never reached: guarded by `is not None`, and `mixed` is
  // not an input — see FINDINGS F3).
  rule <k> itype(F:Field) => F ... </k>
       requires F =/=K none andBool F =/=K mixed

  // ---- x in {DateField, DateTimeField, TimeField} -------------------
  rule <k> temporalSet(F:Field) => isTemporal(F) ... </k>

  // ---- x is not None ------------------------------------------------
  rule <k> notNone(none)    => false ... </k>
  rule <k> notNone(F:Field) => true  ... </k> requires F =/=K none

  // ---- == and `and` -------------------------------------------------
  rule <k> F1:Field eq F2:Field => F1 ==K F2   ... </k>
  rule <k> B1:Bool  and B2:Bool => B1 andBool B2 ... </k>

  // ---- super()._resolve_output_field() : black-box base result ------
  rule <k> base => baseVal(L, R) ... </k> <lhs> L </lhs> <rhs> R </rhs>

  // ---- control flow + return ----------------------------------------
  rule <k> if true  then S1 else _  => S1 ... </k>
  rule <k> if false then _  else S2 => S2 ... </k>
  rule <k> return F:Field => .K ... </k> <out> _ => F </out>

  // ===================================================================
  // Spec-only helper functions (vocabulary, not language constructs)
  // ===================================================================

  // membership in the temporal set {DateField, DateTimeField, TimeField}
  syntax Bool ::= isTemporal(Field) [function, total]
  rule isTemporal(DateField)     => true
  rule isTemporal(DateTimeField) => true
  rule isTemporal(TimeField)     => true
  rule isTemporal(F:Field)       => false
       requires F =/=K DateField andBool F =/=K DateTimeField andBool F =/=K TimeField

  // the UNCHANGED base method's result on sources (L,R), at arity 2.
  // Left uninterpreted EXCEPT the always-true identity below; for L =/= R it
  // denotes "whatever BaseExpression._resolve_output_field returns", which the
  // fix preserves verbatim (incl. the isinstance-subclass asymmetry, F4).
  syntax Field ::= baseVal(Field, Field) [function]
  rule baseVal(F:Field, F:Field) => F     // identical internal types are always compatible

  // the exact temporal-subtraction predicate used by the FIX (lines 451-457)
  syntax Bool ::= isTempSub(Conn, Field, Field) [function, total]
  rule isTempSub(C:Conn, L:Field, R:Field)
    => C ==K SUB andBool (L =/=K none) andBool (R =/=K none)
         andBool isTemporal(L) andBool (L ==K R)
endmodule

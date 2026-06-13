// validators-mini.k
// ---------------------------------------------------------------------------
// Minimal "mini-Python" K semantics for the slice of django.core.validators
// that this fix touches: the *rejection path* of a validator's __call__, and
// the message-rendering step in ValidationError.__iter__ (`message %= params`).
//
// The patched code uses no loops and no recursion, so there are NO loop/recursion
// circularities to discharge (see PROOF.md). The whole content is straight-line:
// a guard -> raise(message, code, params) where params now binds "value".
//
// CONSTRUCTED, NOT MACHINE-CHECKED: this environment has no K toolchain
// (kompile/kprove). The file is written to be faithful and to carry the exact
// run-commands in PROOF.md.
// ---------------------------------------------------------------------------

module VALIDATORS-MINI-SYNTAX
  imports INT-SYNTAX
  imports BOOL-SYNTAX
  imports STRING-SYNTAX

  // Opaque program value being validated (a str / int / None / File / Decimal).
  // Kept abstract: the proof never inspects its structure, only its identity.
  syntax Val

  // Opaque (possibly lazy gettext) message and error code.
  syntax Msg
  syntax Code

  // The ValidationError object:  verr(message, code, params:Map).
  syntax Exc ::= "noExc"
               | "verr" "(" Msg "," Code "," Map ")"

  // Fragment statements. `reject(V, M, C, P)` models exactly one guarded
  // raise site:  `if invalid(V): raise ValidationError(M, code=C, params=P)`.
  syntax Stmt ::= "reject" "(" Val "," Msg "," Code "," Map ")"
                | "accept"                       // the implicit `return None`

  // The render step modelled from ValidationError.__iter__:  `message %= params`.
  syntax KItem ::= "render" "(" Msg "," Map ")"

  syntax KResult ::= Bool | Msg
endmodule

module VALIDATORS-MINI
  imports VALIDATORS-MINI-SYNTAX
  imports INT
  imports BOOL
  imports STRING
  imports MAP

  configuration
    <k> $PGM:K </k>
    <exc> noExc </exc>      // the raised ValidationError, if any
    <out> .K    </out>      // the rendered message (used by the render claim)

  // --- spec oracles: vocabulary, NOT language constructs (uninterpreted) ------
  // invalid(V): does this validator reject V? (the regex / parse / range test).
  // The fix does not change this predicate at all -- it is the same on V1 and V2.
  syntax Bool ::= invalid ( Val )    [function]
  // noPercent(M): the message string contains no '%' character whatsoever.
  syntax Bool ::= noPercent ( Msg )  [function]

  // --- guarded reject ---------------------------------------------------------
  // Invalid value: record the ValidationError carrying params P, abandon the rest.
  rule <k> reject(V, M, C, P) => .K ... </k>
       <exc> _ => verr(M, C, P) </exc>
    requires invalid(V)
  // Valid value: the guard is false, the raise is skipped (falls through).
  rule <k> reject(V, _M, _C, _P) => .K ... </k>
    requires notBool invalid(V)

  rule <k> accept => .K ... </k>

  // --- message rendering: `message %= params` (Python mapping interpolation) --
  // The ONLY slice the proof needs: a message containing no '%' is returned
  // unchanged by mapping interpolation, regardless of which (extra) keys the
  // params map carries. This is precisely Python's rule that a *mapping*
  // right-operand tolerates unused keys and never raises "not all arguments
  // converted". Substitution of an actual %(value)s placeholder, and the
  // bare-'%' -> ValueError case, are an [ESCALATION BOUNDARY] (the full
  // str.__mod__ semantics is outside the bundled tier) -- see PROOF.md / FINDINGS.md.
  rule <k> render(M, _P) => M ... </k>
       <out> _ => M </out>
    requires noPercent(M)
endmodule

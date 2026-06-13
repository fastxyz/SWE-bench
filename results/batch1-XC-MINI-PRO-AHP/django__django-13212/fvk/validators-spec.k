// validators-spec.k
// ---------------------------------------------------------------------------
// Reachability claims for the validator reject/accept contract and the
// ValidationError render step. Proven by symbolic execution against
// validators-mini.k. No loops/recursion => no circularities.
//
// CONSTRUCTED, NOT MACHINE-CHECKED.
// ---------------------------------------------------------------------------
requires "validators-mini.k"

module VALIDATORS-SPEC
  imports VALIDATORS-MINI

  // (CONTRACT-REJECT)  PO1 + PO5.
  // For an invalid value, the validator raises a ValidationError whose params
  // bind "value" to the *provided* value V. P0 is any pre-existing context
  // params (e.g. .Map, or "max" |-> _ for DecimalValidator, or
  // "extension"/"allowed_extensions" for FileExtensionValidator). The claim
  // asserts the FINAL params still binds "value" |-> V (the same symbolic V
  // from the precondition -- value identity, PO5).
  claim <k> reject(V, M, C, (("value" |-> V) P0:Map)) => .K </k>
        <exc> noExc => verr(M, C, (("value" |-> V) P0)) </exc>
    requires invalid(V)
    [all-path]

  // (CONTRACT-ACCEPT)  PO2.
  // For a valid value, NO exception is raised: the exc cell is untouched.
  // This proves the patch is purely additive on the accept path.
  claim <k> reject(V, _M, _C, _P) => .K </k>
        <exc> noExc => noExc </exc>
    requires notBool invalid(V)
    [all-path]

  // (RENDER-DEFAULT)  PO3.
  // A default message (no '%') renders to itself regardless of the added
  // params -> the rendered output of every built-in default message is
  // unchanged by adding params={'value': value}. No regression.
  claim <k> render(M, (("value" |-> _V) _P:Map)) => M </k>
        <out> .K => M </out>
    requires noPercent(M)
    [all-path]
endmodule

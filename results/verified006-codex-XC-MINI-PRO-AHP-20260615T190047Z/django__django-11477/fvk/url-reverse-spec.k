requires "mini-python.k"

module URL-REVERSE-SPEC
  imports MINI-PYTHON
  imports MAP
  imports K-EQUAL

  // SPEC-PROVENANCE:
  // - E3: "We would discard any arguments that are None."
  // - E4: positional template usage should work when an object may be None.
  claim
    <k> normalizeArgs(ARGS:Values) => ?OUT:Values </k>
    ensures { ?OUT #Equals dropNoneArgs(ARGS) }
    [all-path]

  // SPEC-PROVENANCE:
  // - E2: resolve() returns None for uncaptured optional named groups.
  // - E3: reverse() should discard None arguments.
  claim
    <k> normalizeKwargs(KWS:Map) => ?OUT:Map </k>
    ensures { ?OUT #Equals dropNoneKwargs(KWS) }
    [all-path]

  // SPEC-PROVENANCE:
  // - E1/E2: translate_url() must omit an absent optional named capture.
  claim
    <k> normalizeKwargs((arg1 |-> int(1)) (arg2 |-> None))
      => (arg1 |-> int(1))
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E4: direct positional reverse/template use should omit None.
  claim
    <k> normalizeArgs(int(1) None .Values) => int(1) .Values </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E5: empty strings are not None and must remain supplied.
  claim
    <k> normalizeArgs(str("") .Values) => str("") .Values </k>
    [all-path]
endmodule


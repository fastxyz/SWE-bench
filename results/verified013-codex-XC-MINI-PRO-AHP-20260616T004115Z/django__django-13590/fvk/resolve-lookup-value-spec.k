requires "mini-python.k"

module RESOLVE-LOOKUP-VALUE-SPEC
  imports MINI-PYTHON-LOOKUP

  // SPEC-PROVENANCE:
  // - IE2: expression-like values are resolved by resolve_expression().
  claim <k> resolve(expr(V:Value)) => V </k> [all-path]

  // SPEC-PROVENANCE:
  // - IE7: scalar fallthrough behavior is outside the named tuple bug and is
  //   preserved as a frame condition.
  claim <k> resolve(atom(I:Int)) => atom(I) </k> [all-path]

  // SPEC-PROVENANCE:
  // - IE3: list members are recursively resolved.
  // - IE7: non-named container reconstruction remains list-shaped.
  claim
    <k> resolve(list(V1:Value ; V2:Value ; .Values))
      => list(resolve(V1) ; resolve(V2) ; .Values) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - IE3: tuple members are recursively resolved.
  // - IE7: plain tuple reconstruction remains tuple-shaped.
  claim
    <k> resolve(tuple(V1:Value ; V2:Value ; .Values))
      => tuple(resolve(V1) ; resolve(V2) ; .Values) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - IE1: named two-tuples are in-domain __range values.
  // - IE3: tuple elements are recursively resolved.
  // - IE4: the named tuple type/shape is preserved.
  // - IE5: resolved contents are expanded positionally into the constructor.
  claim
    <k> resolve(ntuple(N:String, V1:Value ; V2:Value ; .Values))
      => ntuple(N, resolve(V1) ; resolve(V2) ; .Values) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - default-domain: standard named tuples of any finite arity share the same
  //   constructor rule; the public issue only requires arity two.
  claim
    <k> resolve(ntuple(N:String, VS:Values))
      => ntuple(N, resolveAll(VS)) </k>
    [all-path]
endmodule

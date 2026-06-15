requires "mini-django-pk.k"

module MINI-DJANGO-PK-SPEC
  imports MINI-DJANGO-PK
  imports MAP
  imports INT
  imports BOOL

  syntax Map ::= setChain(Map, Map, Int, Val) [function]
  syntax Bool ::= acyclicFrom(Map, Int) [function]
  syntax Bool ::= inPkChain(Map, Int, Int) [function]

  rule setChain(A:Map, NEXT:Map, F:Int, V:Val) => A [F <- V]
    requires NEXT [F] ==K noParent
    [simplification]

  rule setChain(A:Map, NEXT:Map, F:Int, V:Val) => setChain(A [F <- V], NEXT, G, V)
    requires NEXT [F] ==K parent(G:Int)
    [simplification]

  rule inPkChain(_:Map, F:Int, P:Int) => true
    requires P ==Int F
    [simplification]

  rule inPkChain(NEXT:Map, F:Int, P:Int) => inPkChain(NEXT, G, P)
    requires P =/=Int F andBool NEXT [F] ==K parent(G:Int)
    [simplification]

  rule inPkChain(NEXT:Map, F:Int, P:Int) => false
    requires P =/=Int F andBool NEXT [F] ==K noParent
    [simplification]

  // SPEC-PROVENANCE:
  // - E3/E4: `pk = None` must set the child parent-link field and every
  //   inherited parent PK in a multi-level parent-link primary-key chain.
  // - E5: the chain is rooted at self._meta.pk and does not include unrelated
  //   parent links merely because they exist in self._meta.parents.
  // - implementation fact: V1 loops by assigning field.attname, then following
  //   field.target_field only while remote_field.parent_link is true.
  claim
    <k> setPk(F:Int, V:Val) => .K ... </k>
    <attrs> A:Map => setChain(A, NEXT, F, V) </attrs>
    <next> NEXT:Map </next>
    requires acyclicFrom(NEXT, F)
    [all-path]

  // SPEC-PROVENANCE:
  // - E2/E7: if every PK value consulted by `_save_parents()`/`_save_table()`
  //   along the active chain is None, ordinary save cannot update the old row
  //   through those PKs.
  // - This is a consequence claim over the abstract chain state, not a full
  //   database semantics.
  claim
    <k> setPk(F:Int, None) => .K ... </k>
    <attrs> A:Map => setChain(A, NEXT, F, None) </attrs>
    <next> NEXT:Map </next>
    requires acyclicFrom(NEXT, F)
    ensures inPkChain(NEXT, F, P:Int) impliesBool
      (setChain(A, NEXT, F, None) [P] ==K None)
    [all-path]
endmodule

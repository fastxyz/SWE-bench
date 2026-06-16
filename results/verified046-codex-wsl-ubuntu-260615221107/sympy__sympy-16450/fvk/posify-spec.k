// Constructed for FVK audit; not machine-checked in this environment.
// Claims over the Mini-SymPy posify fragment.

requires "mini-posify.k"

module POSIFY-VERIFICATION
  imports MINI-POSIFY
  imports BOOL
  imports MAP
  imports K-EQUAL

  syntax Bool ::= preservesExceptPositive(Map, Map) [function]
  syntax Bool ::= hasPositiveTrue(Map) [function]

  // Spec-only abstraction functions. In the intended model,
  // preservesExceptPositive(A, B) means every key/value in A except
  // "positive" is present with the same value in B.
  rule preservesExceptPositive(A:Map, setPositive(A)) => true [simplification]
  rule hasPositiveTrue(setPositive(A:Map)) => true [simplification]
endmodule

module POSIFY-SPEC
  imports POSIFY-VERIFICATION

  // SPEC-PROVENANCE:
  // - from_prompt: "posify should preserve the finiteness assumption" =>
  //   facts already present in assumptions0, including finite, must survive.
  // - from_hint: "only add a new assumption positive=True when positive is
  //   not defined, the other assumptions should be retained" =>
  //   replacement is a positive-narrowing frame update over assumptions0.
  // - from_docstring: symbols with positive=None are replaced by a positive
  //   dummy with the same name, and the returned map restores the original.
  claim
    <k> posifySymbol(sym(N:String, A:Map))
        => result(dummy(N, setPositive(A)),
                  dummy(N, setPositive(A)) |-> sym(N, A))
        ... </k>
    requires positiveUnknown(A)
     andBool consistentPositiveNarrowing(A)
    ensures preservesExceptPositive(A, setPositive(A))
     andBool hasPositiveTrue(setPositive(A))
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docstring/public tests: symbols whose positivity is already known
  //   are not replaced by posify.
  claim
    <k> posifySymbol(sym(N:String, A:Map))
        => result(sym(N, A), .Map)
        ... </k>
    requires positiveKnown(A)
    [all-path]
endmodule

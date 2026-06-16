requires "mini-sympy-string.k"

module MINI-SYMPY-STRING-SPEC
  imports MINI-SYMPY-STRING

  // SPEC-PROVENANCE:
  // - E1/E2: String must satisfy Basic positional reconstruction.
  // - E3/E4/E6: args must contain Basic objects, so the text carrier is Str.
  claim
    <k> construct(C:Class, pyStr(S:String))
      => obj(C, S, arg(strAtom(S))) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E1/E2: expr.func(*expr.args) == expr.
  claim
    <k> reconstruct(obj(C:Class, S:String, arg(strAtom(S))))
      => obj(C, S, arg(strAtom(S))) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E5: kwargs reconstruction remains public behavior.
  claim
    <k> kwargs(obj(C:Class, S:String, arg(strAtom(S))))
      => kw(S) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - I4: public non-string text remains invalid.
  claim
    <k> construct(C:Class, other) => typeError </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - E7: default codegen atoms expose String leaves, not internal Str.
  claim
    <k> atomsDefault(obj(C:Class, S:String, arg(strAtom(S))))
      => atomSet(arg(obj(C, S, arg(strAtom(S))))) </k>
    [all-path]
endmodule

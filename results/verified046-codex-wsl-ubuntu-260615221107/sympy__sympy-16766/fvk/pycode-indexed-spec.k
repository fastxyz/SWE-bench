requires "mini-python-printer.k"

module PYCODE-INDEXED-SPEC
  imports MINI-PYCODE-INDEXED

  // SPEC-PROVENANCE:
  // - from_prompt: "pycode(p[0])" should not emit "Not supported in Python: Indexed".
  // - from_prompt: requested output form is native Python subscript syntax.
  // - from_code: IndexedBase exposes a label property; Indexed exposes base and indices.
  claim render(Indexed(IndexedBase(Sym("p")), IntLit(0)))
    => "p[0]"

  // SPEC-PROVENANCE:
  // - from_prompt: the suggested implementation joins all indices with ", ".
  // - from_code: expr.indices preserves the Indexed argument order.
  claim render(Indexed(IndexedBase(Sym("A")), Sym("i") "," Sym("j")))
    => "A[i, j]"

  // SPEC-PROVENANCE:
  // - from_code: Idx._sympystr prints its label; Idx is a common index type for Indexed.
  // - from_formalize: recursive index printing must not route Idx through unsupported Expr.
  claim render(Indexed(IndexedBase(Sym("A")), Idx(Sym("i"))))
    => "A[i]"

  // SPEC-PROVENANCE:
  // - from_code: PythonCodePrinter should preserve normal symbol rendering for the base label.
  // - from_default_domain: using the printer recursively preserves reserved-word handling.
  claim render(Indexed(IndexedBase(Sym("if_")), IntLit(0)))
    => "if_[0]"
endmodule

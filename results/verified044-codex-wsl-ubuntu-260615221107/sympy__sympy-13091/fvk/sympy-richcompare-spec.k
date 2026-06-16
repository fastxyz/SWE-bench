requires "mini-python-richcompare.k"

module SYMPY-RICHCOMPARE-SPEC
  imports MINI-PYTHON-RICHCOMPARE

  // SPEC-PROVENANCE:
  // - from_prompt: "return NotImplemented when unable to make sense of the arguments"
  // - from_code: Basic.__eq__ catches SympifyError
  claim <k> basicEq(BasicUnsympifiable) => RNotImplemented </k> [all-path]

  // SPEC-PROVENANCE:
  // - from_hint: different SymPy types after sympification must also delegate
  // - from_code: Basic.__eq__ compares type(self) != type(other)
  claim <k> basicEq(BasicDifferentType) => RNotImplemented </k> [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: rich comparison fallback must not be swallowed by __ne__
  // - from_code: Basic.__ne__ previously negated __eq__ directly
  claim <k> basicNe(BasicUnsympifiable) => RNotImplemented </k> [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: reflected comparison should be delegated to the other object
  claim <k> pyEq(RNotImplemented, RTrue) => RTrue </k> [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: if both sides return NotImplemented, final equality is False
  claim <k> pyEq(RNotImplemented, RNotImplemented) => RFalse </k> [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "__lt__, __ge__, and so on, behave similarly"
  // - from_code: Expr ordering catches SympifyError
  claim <k> exprOrder(Lt, OrderUnsympifiable) => RNotImplemented </k> [all-path]
  claim <k> exprOrder(Ge, OrderUnsympifiable) => RNotImplemented </k> [all-path]

  // SPEC-PROVENANCE:
  // - from_public_intent: recognized invalid complex/NaN ordering remains invalid
  claim <k> exprOrder(Lt, OrderInvalidComplexOrNaN) => RTypeError </k> [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: core numeric overrides must not bypass fallback
  // - from_prompt: supported Float/float comparison remains definite
  claim <k> numberEq(NumUnknown) => RNotImplemented </k> [all-path]
  claim <k> numberEq(NumNonNumberBasic) => RNotImplemented </k> [all-path]
  claim <k> numberNe(NumUnknown) => RNotImplemented </k> [all-path]
  claim <k> numberEq(NumKnown) => RBool </k> [all-path]

  // SPEC-PROVENANCE:
  // - from_code: singleton equality was identity/known-number based before V1
  // - proof_finding: V1 sympification widened equality without public evidence
  claim <k> singletonEq(SingletonSame) => RTrue </k> [all-path]
  claim <k> singletonEq(SingletonOtherNumber) => RFalse </k> [all-path]
  claim <k> singletonEq(SingletonUnsupported) => RNotImplemented </k> [all-path]
  claim <k> singletonNe(SingletonUnsupported) => RNotImplemented </k> [all-path]
endmodule

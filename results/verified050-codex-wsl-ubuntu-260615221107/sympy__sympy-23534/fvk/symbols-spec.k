requires "mini-symbols.k"

module SYMBOLS-SPEC
  imports MINI-SYMBOLS

  // SPEC-PROVENANCE:
  // - from_prompt: "symbols(('q:2', 'u:2'), cls=Function)" should make
  //   type(q[0]) be UndefinedFunction.
  // - from_docs: symbols can create Function-like objects by setting cls.
  // - from_code: Function(name) constructs an UndefinedFunction when cls is
  //   Function.
  // Claim: SYMBOLS-FUNCTION-NESTED-RANGES
  claim
    <k>
      symbols(
        tuple(range("q", 0, 2) ; range("u", 0, 2) ; .NameSpecs),
        FunctionCls
      )
      =>
      tupleValue(
        tupleValue(
          atom(obj(FunctionCls, "q0")) ;
          atom(obj(FunctionCls, "q1")) ;
          .Values
        ) ;
        tupleValue(
          atom(obj(FunctionCls, "u0")) ;
          atom(obj(FunctionCls, "u1")) ;
          .Values
        ) ;
        .Values
      )
    </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: the extra iterable layer must not cause Function to become
  //   Symbol.
  // - from_docs: cls is a general constructor selector for symbol-like objects.
  // - from_code: the iterable branch is the only recursive symbols() self-call.
  // Claim: SYMBOLS-ITERABLE-PRESERVES-CLASS
  claim
    <k>
      symbols(tuple(N:NameSpec ; NS:NameSpecs), C:Class)
      =>
      tupleValue(symbolsValue(N, C) ; symbolsEach(NS, C))
    </k>
    [all-path]
endmodule

requires "mini-quantity-input.k"

module QUANTITY-INPUT-SPEC
  imports MINI-QUANTITY-INPUT

  // SPEC-PROVENANCE:
  // - from_prompt: "constructors with type hinted return value -> None" =>
  //   a None return annotation is a no-return type hint, not a unit target.
  // - from_prompt: "'NoneType' object has no attribute 'to'" =>
  //   the old .to path on a None result is the reported bug.
  claim <k> wrapper(noneAnn, noneRet) => returned(noneRet) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt: "correct return value for the constructor (`None`)" =>
  //   the decorator must leave no-return annotations alone.
  // - from_code: V1 branches away from .to when annotation is None.
  claim <k> wrapper(noneAnn, R:Ret) => returned(R) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_default_behavior: without a return annotation, quantity_input is an
  //   argument validator and does not convert the return value.
  claim <k> wrapper(emptyAnn, R:Ret) => returned(R) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_docs_or_tests: return unit annotations convert to that unit.
  // - frame: preserve the documented non-None return annotation behavior.
  claim <k> wrapper(unitAnn(TO:String), quantity(FROM:String))
        => converted(quantity(TO), unitAnn(TO)) </k>
    [all-path]

  // SPEC-PROVENANCE:
  // - from_prompt traceback: the old code called .to on a None return value.
  // - this is a counterexample witness for the pre-fix implementation, not a
  //   behavior to preserve.
  claim <k> buggyWrapper(noneAnn, noneRet)
        => attrError("NoneType.to") </k>
    [all-path]
endmodule

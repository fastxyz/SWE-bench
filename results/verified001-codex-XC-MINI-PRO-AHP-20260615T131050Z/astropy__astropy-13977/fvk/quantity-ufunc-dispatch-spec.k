requires "mini-ufunc-dispatch.k"

module QUANTITY-UFUNC-DISPATCH-SPEC
  imports MINI-UFUNC-DISPATCH
  imports BOOL

  // SPEC-PROVENANCE:
  // - from_prompt: Quantity.__array_ufunc__ should return NotImplemented
  //   instead of raising ValueError for an unrecognized duck array with unit.
  // - from_hint: only recognized classes should be handled; inputs+out should
  //   be checked.
  // - from_code: Q represents Quantity; ND represents ndarray subclasses,
  //   including table Columns; OTHER_UNIT represents a non-recognized object
  //   with a unit attribute.
  claim
    <k> quantityArrayUfunc(IS:Objs ; OS:Objs) => NOT_IMPLEMENTED </k>
    requires hasUnsupported(concat(IS ; OS)) ==Bool true
    [all-path]

  // SPEC-PROVENANCE:
  // - from_hint: Quantity, ndarray, and Column should continue to work.
  // - from_issue_scope: plain non-unit arguments are not the reported bug.
  claim
    <k> quantityArrayUfunc(IS:Objs ; OS:Objs) => PROCEED </k>
    requires hasUnsupported(concat(IS ; OS)) ==Bool false
    [all-path]
endmodule


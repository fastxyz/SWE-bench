requires "mini-python-mask.k"

module NDARITHMETIC-MASK-SPEC
  imports MINI-PYTHON-MASK
  imports INT
  imports BOOL

  // SPEC-PROVENANCE:
  // - L8: handle_mask=None means the result has no mask.
  claim <k> arithMask(SM:Mask, OP:Operand, NoHandle) => NoMask </k>
    [label(MASK-NONE-HANDLE), all-path]

  // SPEC-PROVENANCE:
  // - L3, L7: if neither side has a mask, the result mask is None.
  claim <k> arithMask(NoMask, AbsentOperand, CallableMask) => NoMask </k>
    [label(MASK-BOTH-ABSENT), all-path]

  // SPEC-PROVENANCE:
  // - L3, L7: binary no-mask/no-mask arithmetic returns no mask.
  claim <k> arithMask(NoMask, Operand(NoMask), CallableMask) => NoMask </k>
    [label(MASK-BOTH-NONE), all-path]

  // SPEC-PROVENANCE:
  // - L2, L7: if only the right operand has a mask, copy that mask.
  claim <k> arithMask(NoMask, Operand(OM:Mask), CallableMask) => Copy(OM) </k>
    requires OM =/=K NoMask
    [label(MASK-RIGHT-ONLY), all-path]

  // SPEC-PROVENANCE:
  // - L2, L7: if the left operand has the only mask and the right operand is
  //   absent, copy the left mask.
  claim <k> arithMask(SM:Mask, AbsentOperand, CallableMask) => Copy(SM) </k>
    requires SM =/=K NoMask
    [label(MASK-LEFT-ONLY-ABSENT-OPERAND), all-path]

  // SPEC-PROVENANCE:
  // - L1, L2, L5, L7: if the left operand has the only mask and the right
  //   operand exists with mask=None, copy the left mask instead of invoking
  //   handle_mask with None.
  claim <k> arithMask(SM:Mask, Operand(NoMask), CallableMask) => Copy(SM) </k>
    requires SM =/=K NoMask
    [label(MASK-LEFT-ONLY-MASKLESS-OPERAND), all-path]

  // SPEC-PROVENANCE:
  // - L4, L7: if both masks are present, delegate to the mask-combining callable.
  claim <k> arithMask(SM:Mask, Operand(OM:Mask), CallableMask) => Combined(SM, OM) </k>
    requires SM =/=K NoMask andBool OM =/=K NoMask
    [label(MASK-BOTH-PRESENT), all-path]

  // SPEC-PROVENANCE:
  // - L1, L2, L7: binary scalar arithmetic wraps the scalar as a maskless
  //   operand, so callable propagation copies the present left mask.
  claim <k> binaryCallableMask(SM:Mask, NoMask) => Copy(SM) </k>
    requires SM =/=K NoMask
    [label(BINARY-SCALAR-MASKLESS-RIGHT), all-path]
endmodule

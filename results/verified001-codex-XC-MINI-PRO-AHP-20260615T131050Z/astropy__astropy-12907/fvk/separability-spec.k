requires "mini-python-separability.k"

module SEPARABILITY-SPEC
  imports MINI-SEPARABILITY
  imports INT
  imports BOOL

  // SPEC-PROVENANCE:
  // - INT-4: coord matrices have shape (n_outputs, n_inputs).
  // - INT-5: CompoundModel('&') adds left and right input/output counts.
  claim [CSTACK-SHAPE-ROWS]:
    <k> rows(cstack(L, R)) => rows(L) +Int rows(R) </k>
    requires rows(L) >=Int 0 andBool rows(R) >=Int 0

  claim [CSTACK-SHAPE-COLS]:
    <k> cols(cstack(L, R)) => cols(L) +Int cols(R) </k>
    requires cols(L) >=Int 0 andBool cols(R) >=Int 0

  // SPEC-PROVENANCE:
  // - INT-2: a left nonseparable block must not disturb later independent blocks.
  // - INT-4/INT-5: '&' is block concatenation in output/input order.
  claim [CSTACK-LEFT-PRESERVE]:
    <k> dep(cstack(L, R), I, J) => dep(L, I, J) </k>
    requires 0 <=Int I andBool I <Int rows(L)
     andBool 0 <=Int J andBool J <Int cols(L)

  // SPEC-PROVENANCE:
  // - INT-1: Linear1D & Linear1D has diagonal dependencies.
  // - INT-3: nesting a right-hand '&' compound must preserve that matrix.
  // - INT-6 is suspect legacy evidence and is rejected.
  claim [CSTACK-RIGHT-PRESERVE]:
    <k> dep(cstack(L, R), rows(L) +Int I, cols(L) +Int J)
      => dep(R, I, J)
    </k>
    requires 0 <=Int I andBool I <Int rows(R)
     andBool 0 <=Int J andBool J <Int cols(R)

  // SPEC-PROVENANCE:
  // - INT-2/INT-3: '&' concatenation does not introduce cross dependencies.
  claim [CSTACK-OFF-BLOCKS-UPPER-RIGHT]:
    <k> dep(cstack(L, R), I, cols(L) +Int J) => false </k>
    requires 0 <=Int I andBool I <Int rows(L)
     andBool 0 <=Int J andBool J <Int cols(R)

  claim [CSTACK-OFF-BLOCKS-LOWER-LEFT]:
    <k> dep(cstack(L, R), rows(L) +Int I, J) => false </k>
    requires 0 <=Int I andBool I <Int rows(R)
     andBool 0 <=Int J andBool J <Int cols(L)

  // SPEC-PROVENANCE:
  // - INT-3: parenthesizing a right-hand '&' compound must not alter its entries.
  claim [CSTACK-NESTED-RIGHT]:
    <k> dep(cstack(A, cstack(B, C)), rows(A) +Int I, cols(A) +Int J)
      => dep(cstack(B, C), I, J)
    </k>
    requires 0 <=Int I andBool I <Int rows(B) +Int rows(C)
     andBool 0 <=Int J andBool J <Int cols(B) +Int cols(C)
endmodule

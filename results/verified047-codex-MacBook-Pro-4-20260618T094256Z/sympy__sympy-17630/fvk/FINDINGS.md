# Findings

Status: constructed, not machine-checked.

## F1: V1 Addresses The Reported Defect Mechanism

Evidence:

- Public issue: repeated block multiplication fails because zero result blocks
  are scalar `Zero` and later block-size access reads `.cols`.
- K claims: `NORMALIZE-SCALAR-ZERO`,
  `BLOCKMUL-COMPATIBLE-ZERO-ENTRY`, and `BLOCKMUL-REPEATED-SAFE`.

Finding:

For any compatible block product entry whose raw value is exact scalar zero,
V1 converts that entry to a shaped `ZeroMatrix` using the row block size from
the left operand and the column block size from the right operand. The result
entry is therefore matrix-shaped for later multiplication.

Decision:

No source edit is required.

## F2: V1 Preserves Already Matrix-Valued Product Entries

Evidence:

- Public issue identifies scalar zero blocks as the failing case, not nonzero
  matrix entries.
- K claims: `NORMALIZE-MATRIX-PRESERVE` and
  `BLOCKMUL-COMPATIBLE-MATRIX-ENTRY`.

Finding:

The V1 normalization is conditional: entries already recognized as matrix
objects are returned unchanged. This preserves ordinary block multiplication
results such as the `a**2` block in the issue example.

Decision:

No source edit is required.

## F3: V1 Preserves Fallback Behavior

Evidence:

- Public in-repo tests cover `_blockmul` with non-`BlockMatrix` operands.
- K claims: `BLOCKMUL-NONBLOCK-FALLBACK` and
  `BLOCKMUL-INCOMPATIBLE-FALLBACK`.

Finding:

V1 only changes the compatible `BlockMatrix` branch after the raw block-grid
product is computed. Non-`BlockMatrix` and incompatible-`BlockMatrix` calls
continue to return the ordinary multiplication fallback.

Decision:

No source edit is required.

## Proof-Derived Findings From `/verify`

No proof-derived counterexample or unmet proof obligation was found that V1
demonstrably fails. The audit therefore confirms V1 unchanged.

## Residual Risks

The proof artifacts are constructed but not machine-checked. The mini-semantics
abstracts the relevant block-entry shape behavior and does not model all SymPy
simplification internals or full Python execution.

No test removal is recommended unless the emitted K commands are later run and
`kprove` returns `#Top`.

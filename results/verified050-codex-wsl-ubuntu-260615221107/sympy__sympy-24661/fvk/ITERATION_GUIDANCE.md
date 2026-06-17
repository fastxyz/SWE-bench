# FVK Iteration Guidance for sympy__sympy-24661

Status: V1 stands unchanged after FVK audit.

## Decision

Do not edit production source beyond the existing V1 patch. The current
`visit_Compare` implementation discharges the public issue intent and the proof
obligations in `fvk/PROOF_OBLIGATIONS.md`.

## Why No Additional Code Change Is Justified

- F1 and PO1/PO4 show the reported `parse_expr('1 < 2', evaluate=False)` bug is
  addressed at the AST comparison node that produced the symptom.
- F2 and PO5 show the `sympify` example is addressed through existing string
  delegation to `parse_expr`.
- F3 and PO1/PO2/PO3 show the standard Python comparison operator family is
  covered, not only the single `<` example.
- F4 and PO2 show chained comparison nodes are handled within the same AST
  family.
- F5 and PO6 explain why adding relation constructor names to the generic
  `visit_Call` whitelist was not adopted: it is broader than the public syntax
  bug and can affect local name-shadowing behavior.

## Recommended Follow-Up Tests

Do not modify test files in this benchmark. In a normal development environment,
add or keep tests for:

- all six standard comparison operators under `parse_expr(..., evaluate=False)`;
- `sympify('1 < 2', evaluate=False)`;
- nested arithmetic operands inside a comparison;
- a chained comparison under `evaluate=False`;
- unsupported Python comparison forms preserving fallback behavior if the
  project wants that behavior pinned explicitly.

## Machine-Checking and Execution Guidance

This run is constructed, not machine-checked. The commands recorded in
`fvk/PROOF.md` were not run and should not be treated as completed verification.
Keep existing tests until a real environment can run both the project tests and
any desired FVK/K commands.


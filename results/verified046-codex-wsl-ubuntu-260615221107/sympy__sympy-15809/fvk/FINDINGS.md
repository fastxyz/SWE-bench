# FVK Findings

Status: constructed, not machine-checked.

## Findings

### F1 - Resolved code bug: empty `Min`/`Max` raised instead of returning identities

- Input: `Min()` and `Max()`
- Pre-V1 observed behavior from source and issue: `MinMaxBase.__new__` raised
  `ValueError("The Max/Min functions must have arguments.")` before any lattice
  identity handling.
- Expected behavior from public intent: `Min()` returns `oo`; `Max()` returns
  `-oo`.
- V1 status: resolved. The empty branch now returns `cls.identity`, and the
  concrete subclasses define `Min.identity = S.Infinity` and
  `Max.identity = S.NegativeInfinity`.
- Related proof obligations: PO1, PO2, PO3.

### F2 - SUSPECT legacy tests: visible tests assert the reported bug

- Input: visible public test assertions
  `raises(ValueError, lambda: Min())` and
  `raises(ValueError, lambda: Max())`.
- Observed evidence: these tests encode the exception that the public issue
  describes as inconvenient and asks to replace.
- Expected behavior from public intent: tests should assert `Min() == oo` and
  `Max() == -oo` when test edits are allowed.
- V1 status: no source change required. Test files are fixed/hidden for this
  task and must not be modified.
- Related proof obligations: PO1, PO2, PO6.

### F3 - No additional source defect found in V1

- Input: non-empty calls such as `Min(x)` or `Max(x, y)`.
- Observed from static source: V1 changes only the empty-argument branch. All
  non-empty calls continue into the same sympification, filtering, collapse,
  local-zero, and expression-construction code as before.
- Expected behavior from public intent: preserve existing non-empty Min/Max
  semantics.
- V1 status: confirmed under the frame obligation. No V2 source edit is
  justified by this FVK pass.
- Related proof obligations: PO4, PO5.

## Proof-derived Findings from `/verify`

- The proof has no loop invariant or recursion circularity obligations because
  the audited branch is a straight-line constructor branch.
- The only abstraction boundary is the non-empty constructor tail. It is an
  intentional frame abstraction, not a proof of the full Min/Max simplification
  algorithm.
- No verification condition forced an extra precondition beyond the public
  domain: zero arguments are in domain by the issue intent, and non-empty calls
  retain the existing domain checks.


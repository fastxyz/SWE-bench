# FVK Notes

Status: constructed, not machine-checked. No tests, Python, `kompile`, or
`kprove` were run.

## Source changes after V1

Changed `repo/sympy/physics/units/unitsystem.py`.

### Added `UnitSystem._is_dimensionless()`

Reason: FVK finding F2 showed that V1 called
`DimensionSystem.is_dimensionless()` inline in the new function-dimension
normalization path. Proof obligation PO4 requires the new check to be
conservative when the dimension system cannot analyze a dimension expression.

Decision: add a private helper that returns false when there is no dimension
system or when dependency analysis raises `TypeError`. This preserves the V1 fix
for the reported SI dimensionless case because PO1 still holds when the dimension
system returns true.

### Added `UnitSystem._dimensions_equivalent()`

Reason: FVK finding F2 showed that V1 could leak a lower-level `TypeError` from
`DimensionSystem.equivalent_dims()` in the `Add` branch. PO3 requires
incompatible additions to keep raising `ValueError`, and PO4 requires unsupported
dimension analysis to be treated as not equivalent.

Decision: add a private helper that returns true for structural equality, true
for dimension-system equivalence, and false when no dimension system exists or
analysis raises `TypeError`.

### Updated the `Add` branch

Reason: FVK finding F1 confirmed that the original bug was structural comparison
of dimensions that are equivalent under SI, while PO2 requires
`100 + exp(second/(ohm*farad))` to collect successfully. F2 and PO4 required the
equivalence check to be conservative.

Decision: replace `dim != addend_dim` with
`not self._dimensions_equivalent(dim, addend_dim)`. Equivalent dimensions are now
accepted; non-equivalent or unanalyzable dimensions still raise the branch's
existing `ValueError`.

### Updated the `Function` branch

Reason: FVK finding F1 and PO1 require function result dimensions to become
`Dimension(1)` when the collected argument dimension is proven dimensionless.
F2 and PO4 require unsupported dimension analysis not to normalize by accident.

Decision: keep V1's normalization behavior but route it through
`self._is_dimensionless(dim)`.

## Decisions to keep V1 scope

Strict validation of every function argument was not added. FVK finding F3 and
PO5 trace this to public behavior: existing tests preserve dimensionful function
results in some collector paths and reject incompatibility later when such a
result is added to a dimensionless expression.

No tests were modified. F4 and PO6 state that this FVK proof is constructed but
not machine-checked, and the benchmark task forbids editing tests.

No broader canonicalization of every collected dimension was added. The required
obligations are PO1 and PO2 for function results and additive compatibility; a
global canonicalization pass would be a larger behavioral change not required by
the public issue.

## Artifact decisions

The five requested files were written under `fvk/`: `SPEC.md`, `FINDINGS.md`,
`PROOF_OBLIGATIONS.md`, `PROOF.md`, and `ITERATION_GUIDANCE.md`.

Because the FVK docs require a formal core and adequacy audit, I also wrote:

- `fvk/mini-sympy-units.k`;
- `fvk/unitsystem-collect-spec.k`;
- `fvk/INTENT_SPEC.md`;
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`;
- `fvk/FORMAL_SPEC_ENGLISH.md`;
- `fvk/SPEC_AUDIT.md`;
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.

These artifacts record the reduced model, claims, public evidence, compatibility
check, and exact future K commands without executing them.

# FINDINGS.md

Status: constructed, not machine-checked. Findings are based on public intent,
static source inspection, and the constructed proof obligations.

## F-001: Original Leading-Prefix Reversal

Classification: code bug, resolved by V1.

Input class:

```text
prefix P = [rho, sigma]
core branches R = [[]]
coefficient C = 4
```

Observed before V1:

```text
4 * GammaMatrix(sigma) * GammaMatrix(rho)
```

Expected from public intent:

```text
4 * GammaMatrix(rho) * GammaMatrix(sigma)
```

Cause: the legacy loop iterated leading positions left to right while using
`insert(0, ...)`, so the second leading index was prepended before the first.

Resolution: V1 iterates the positions right to left, so repeated prepends
preserve the original prefix order.

Proof obligations: PO-1, PO-3, PO-6.

## F-002: V1 Restores the Prefix for Every Result Branch

Classification: no remaining code bug found in the audited slice.

For arbitrary leading prefix `P` and arbitrary branch list `R`, the V1 loop
applies the same reverse-position prepend sequence to every `ri` in
`resulting_indices`. This discharges the branch-universal restoration
obligation:

```text
restore(P, R) = [P ++ ri for ri in R]
```

Decision: keep V1 unchanged.

Proof obligations: PO-3, PO-4.

## F-003: Full Tensor Algebra Is Framed, Not Reproved

Classification: proof capability gap / scoped verification boundary.

The constructed K model proves the order-restoration slice that the issue and
V1 patch target. It does not mechanize SymPy tensor internals, dummy-index
discovery, the whole Kahane graph traversal, or matrix construction.

This is not a new source bug in V1; it is the trusted context boundary for this
FVK pass. Existing tests should be kept until the emitted K commands are
machine-checked and broader integration behavior remains covered.

Proof obligations: PO-2, PO-5, PO-8.

## F-004: Public API Compatibility Is Preserved

Classification: compatibility check passed.

The public function name, signature, return categories, and imports are
unchanged. The V1 patch only changes the direction of an internal restoration
loop and corrects a nearby comment.

Proof obligations: PO-7.

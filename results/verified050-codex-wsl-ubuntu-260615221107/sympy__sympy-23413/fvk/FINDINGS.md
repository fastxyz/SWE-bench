# FVK Findings

Status: constructed, not machine-checked.

## F1: V1 preserved a legacy rank-deficient tall-matrix bug

Input:

```text
[[2, 7],
 [0, 0],
 [0, 0]]
```

Observed in V1 by static reasoning: the V1 snapshot fallback restored the old
bottom-`n` result when the extended scan did not find all `n` pivots, so this
rank-one matrix would still return a `3 x 0` HNF.

Expected from the HNF contract: the result must contain `rank(A) == 1` column
and generate the same integer column module as the input. Since the two input
columns generate `gcd(2, 7) * e_1 = e_1`, the result should have one column.

Classification: code bug introduced by over-preserving legacy behavior.

Resolution: fixed in V2 by removing the snapshot fallback and letting the
bottom-up pivot search continue through all rows.

Trace: `SPEC.md` contract; `PROOF_OBLIGATIONS.md` PO5 and PO6.

## F2: Original issue was caused by stopping after the bottom `min(m, n)` rows

Input:

```text
[[1, 12],
 [0,  8],
 [0,  5]]
```

Observed pre-fix behavior from the issue: HNF returned one column, which made
the user's flip/transpose workaround lose a row.

Expected: HNF returns two columns:

```text
[[1, 0],
 [0, 8],
 [0, 5]]
```

Classification: code bug in the original outer-loop bound.

Resolution: fixed by scanning all rows until either all columns become pivots
or no rows remain.

Trace: public evidence E2-E4; `PROOF_OBLIGATIONS.md` PO4-PO7.

## F3: Existing zero-column public test is suspect legacy evidence

Evidence: an in-repo public test expects a rank-positive tall matrix
`[[2, 7], [0, 0], [0, 0]]` to return a `3 x 0` matrix.

Conflict: that expectation contradicts rank and column-module preservation for
HNF. The FVK intent rules treat public tests as evidence, not an oracle, when
they conflict with bug-fix intent or the public API contract.

Classification: suspect legacy test expectation, not a reason to keep V1.

Resolution: do not edit tests in this task; production code now follows the HNF
contract.

Trace: public evidence E7; `SPEC_AUDIT.md` rank-deficient tall row.

## F4: Formal proof is constructed over a mini-HNF abstraction

The `.k` files model the row/column/rank/module properties relevant to the
defect, but they are not full Python or full `DomainMatrix` semantics. The
algebraic obligations for gcd-based column operations and HNF canonicality are
spelled out in `PROOF_OBLIGATIONS.md`.

Classification: proof capability boundary, not a code bug.

Resolution: exact `kompile` and `kprove` commands are recorded in `PROOF.md`.
They were not run, per task instructions.

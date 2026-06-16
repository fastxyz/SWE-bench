# FVK Findings

Status: constructed, not machine-checked.

## FVK-F1: Pre-V1 Pruning Used Stale Indexes

Classification: code bug, resolved by V1.

Evidence: `benchmark/PROBLEM.md` reports `IndexError` in
`minimal_blocks()` at `del num_blocks[i], blocks[i]`.

Concrete symbolic input:

- `rep_blocks` has length 2.
- Both existing representative blocks strictly contain the new representative
  block, so the comparison loop marks indexes `0` and `1` for removal.

Observed pre-V1 behavior:

- On `i == 0`, the code deleted `blocks[0]` and `num_blocks[0]`, shortening
  both lists to length 1 while the enumeration over the original `rep_blocks`
  continued.
- On `i == 1`, it attempted to delete index `1` from a length-1 list, raising
  `IndexError`.

Expected behavior:

- The code should remove both marked block systems and continue with all three
  parallel lists aligned.

Resolution:

- V1 stores removal indexes during the scan and deletes them afterward in
  descending order from `num_blocks`, `blocks`, and `rep_blocks`.
- Discharged by PO-2, PO-3, and PO-4.

## FVK-F2: V1 Must Preserve Minimal-Block Pruning, Not Merely Suppress the Error

Classification: semantic preservation obligation, resolved by V1.

Evidence: `minimal_blocks()` is documented to return all minimal block systems
for transitive groups. A fix that skipped deletion or caught `IndexError` would
avoid the traceback while leaving non-minimal systems or misaligned state.

Expected behavior:

- Every existing block system marked non-minimal by the original comparison
  predicate is removed.
- Unmarked block systems are retained in their original relative order.
- The candidate block system is appended under the same `minimal and num_block
  not in num_blocks` condition as before.

Resolution:

- V1 changes only when deletion occurs, not which indexes are selected or when
  the candidate append condition is evaluated.
- Discharged by PO-4 and PO-5.

## FVK-F3: No Caller or API Compatibility Problem Was Introduced

Classification: compatibility check, resolved.

Evidence: `sylow_subgroup()` calls `blocks = self.minimal_blocks()` and then
passes entries to `block_homomorphism()`. V1 does not change the public method
signature or return shape.

Expected behavior:

- Existing callers still see `False` for intransitive groups or a list of block
  systems for transitive groups.

Resolution:

- V1 is internal to list pruning and does not alter public API shape.
- Discharged by PO-6.

## FVK-F4: Group-Theoretic Completeness Is a Proof Boundary

Classification: proof capability/scope boundary, not a new code bug.

Evidence: The reported traceback is localized to list deletion. Proving the
entire Sylow subgroup algorithm or the mathematical completeness of
`minimal_block()` would require a much larger group-action semantics than the
minimal FVK fragment used here.

Expected behavior for this FVK pass:

- Prove that the mutation kernel causing the traceback is safe and
  semantics-preserving with respect to marked deletions.
- Do not claim a machine-checked proof of the full group-theoretic algorithm.

Resolution:

- The FVK artifacts state this boundary explicitly. V1 stands because the
  concrete public failure is explained and removed at its cause.
- Reflected in PO-7 and `PROOF.md` residual risk.

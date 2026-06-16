# FVK Notes

## Decisions

### Source fix kept unchanged

I kept the V1 change in `repo/sympy/combinatorics/perm_groups.py` unchanged.
`fvk/FINDINGS.md` FVK-F1 identifies the concrete bug as stale indexes caused by
deleting from `blocks` and `num_blocks` while still iterating over original
`rep_blocks` indexes. `fvk/PROOF_OBLIGATIONS.md` PO-2 establishes that V1's
stored removal indexes are valid original indexes, PO-3 establishes that
deleting them in reverse preserves index validity, and PO-4 establishes exact
parallel removal. Together, these obligations justify V1 as the targeted fix for
the reported `IndexError`.

### No broader source refactor

I did not extract a helper or change the surrounding minimal-block comparison
logic. FVK-F2 requires preserving minimal-block pruning semantics, and PO-5
states that the candidate-minimality and duplicate checks are framed by the V1
change. A helper extraction would not discharge a new obligation; it would only
move the same logic, so it was left as future guidance.

### No `sylow_subgroup()` edit

I did not change `sylow_subgroup()`. FVK-F3 records that the caller only relies
on `minimal_blocks()` returning the same kind of block-system data, and PO-6
records that V1 does not change public signatures, return shape, or caller
protocols.

### Formal scope limited to the pruning kernel

The FVK proof targets the list-pruning mutation kernel rather than the full
Sylow subgroup algorithm. FVK-F4 identifies full group-theoretic correctness as
a proof boundary, and PO-7 states why the mini-K model preserves the properties
that distinguish the bug from the fix: list length, index validity, deletion
order, exact removal, and parallel alignment.

### FVK artifacts added

I added the required artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

I also added the formal core required by the FVK docs:

- `fvk/mini-python-list-prune.k`
- `fvk/minimal-blocks-prune-spec.k`

These artifacts encode FVK-F1 through FVK-F4 and PO-1 through PO-7. The proof is
marked constructed, not machine-checked, and the K commands are recorded but not
executed.

### No tests or tools run

I did not run tests, Python, `kompile`, `kast`, or `kprove`, and I did not modify
test files. This follows the task restrictions and is also reflected in
`fvk/PROOF.md`, where test removal is not recommended unless a future
machine-check returns `#Top`.

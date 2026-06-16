# FVK Notes

## Source Decision

No V2 source edit was made after the FVK audit. V1 stands unchanged because every source-level obligation raised by the findings is already discharged:

- `F-001` and `F-003` identify the normal-yield aliasing and caller-mutation hazards. These map to `PO-001` and `PO-002`, which V1 satisfies with `yield ms.copy()`.
- `F-002` identifies the same aliasing issue in `size=True` output. This maps to `PO-003`, which V1 satisfies with `yield sum(ms.values()), ms.copy()`.
- `F-004` records that the full integer-partition enumeration proof is outside this FVK pass. That maps to `PO-004` and `PO-008`: V1 preserves the existing enumeration transition and the artifacts honestly avoid claiming a full enumeration proof.
- `F-005` records that the old docstring caveat was legacy behavior described by the issue as the defect. This maps to `PO-007`, which V1 satisfies by removing the caveat and showing direct `list(partitions(...))` examples.
- `PO-005` justifies leaving single-yield early-return branches unchanged because they do not reuse a mutable dictionary across multiple yields.
- `PO-006` justifies not changing the API, return type, or tuple shape because compatibility would be harmed without improving the reported issue.

## Artifact Decisions

I added the requested FVK artifacts under `fvk/`: `SPEC.md`, `FINDINGS.md`, `PROOF_OBLIGATIONS.md`, `PROOF.md`, and `ITERATION_GUIDANCE.md`. I also added the adequacy and compatibility files required by the FVK docs plus `mini-python-partitions.k` and `partitions-snapshot-spec.k` so the proof is not Markdown-only.

The K model focuses on the yield boundary rather than the whole partition algorithm. That follows `F-004`, `PB-002`, `PO-004`, and `PO-008`: the source change only replaces public aliasing with `dict.copy()`, while the enumeration state machine is unchanged and not re-proved here.

## Execution Decision

I did not run tests, Python, `kompile`, `kast`, or `kprove`, per the task constraints. The proof artifacts include the commands that should be run later, and `PB-001` / `PO-008` keep the result labeled as constructed, not machine-checked.

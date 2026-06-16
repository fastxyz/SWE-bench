# ITERATION_GUIDANCE.md

Status: no V2 source change recommended.

## Decision

Keep V1 unchanged. `fvk/FINDINGS.md` records the original defect as F-001 and a
shared-reducer scope concern as F-002; both are resolved by the existing V1
guard in `Weighted._reduce`. `fvk/PROOF_OBLIGATIONS.md` records no open
obligation requiring a source edit.

## Guidance for a Future Code/Test Iteration

- Do not narrow the fix to `_sum_of_weights`; that would reopen F-002.
- Do not cast after `dot`; that would reopen F-001 because the count may already
  be lost.
- Preserve the conjunctive guard so mixed dtype behavior stays framed by F-003.
- Keep the public API unchanged.
- If tests may be edited in a future non-benchmark setting, add coverage for the
  issue example, boolean `sum_of_weights`, boolean data with boolean weights,
  and the zero-weight denominator.
- Before removing any tests as redundant, run the recorded K commands and require
  `kprove` to return `#Top`.

## Commands to Machine-Check Later

```sh
kompile fvk/mini-weighted.k --backend haskell
kast --backend haskell fvk/weighted-spec.k
kprove fvk/weighted-spec.k
```

These commands are intentionally not run in this task.

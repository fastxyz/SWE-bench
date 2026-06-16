# Iteration Guidance

Status: constructed, not machine-checked.

## Code decision

Keep V1 unchanged.

Reason:

- F-001 identifies the exact pre-V1 defect.
- PO-6 states the corrected right-frame source-column obligation.
- The current source expression `self[i, j - other.cols]` discharges PO-6 for
  every normalized insertion position, including the issue's interior
  multi-column case.
- F-004 and PO-8 found no public compatibility blocker.

## Rejected alternatives

### Revert to `j - pos - other.cols`

Rejected because it fails F-001 and PO-6 whenever `pos > 0`: the first column to
the right of the inserted block would read original column `0` instead of
original column `pos`.

### Change position normalization

Rejected because no FVK finding implicates position normalization. PO-1 is
already discharged by the existing public method and the visible public tests
support Python-list-like clamping behavior.

### Change sparse matrix insertion

Rejected because sparse insertion already shifts existing columns by
`other.cols`, matching PO-6 and supporting compatibility evidence E7.

### Remove the unused local `cols = self.cols`

Rejected as unrelated cleanup. It is not needed to discharge any proof
obligation or finding, and the task calls for minimal production changes.

## Suggested future tests

Do not edit tests in this benchmark task. For a normal development branch, add a
regression test for interior multi-column insertion preserving nonzero
right-side entries, such as the reported identity-matrix case.

## Suggested future machine check

Run the recorded commands in an environment with K installed:

```sh
cd fvk
kompile mini-matrix.k --backend haskell
kast --backend haskell col-insert-spec.k
kprove col-insert-spec.k
```

Expected result: `kprove` returns `#Top`.

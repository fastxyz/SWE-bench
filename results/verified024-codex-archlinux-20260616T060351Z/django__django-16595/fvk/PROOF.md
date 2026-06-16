# FVK Proof

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Claims

The supporting K files are:

`fvk/mini-migration-optimizer.k`

`fvk/alter-field-reduce-spec.k`

The claims state:

1. A same-field `AlterField` pair reduces to the later `AlterField`.
2. A three-operation same-field `AlterField` chain reduces to the third
   operation under repeated optimization.
3. A different model/field `AlterField` pair is not reduced by the new branch.

These are the K counterparts of PO-001, PO-004, and PO-006.

## Constructed Proof Sketch

For PO-001, symbolic execution enters `AlterField.reduce()`. The first branch in
V1 checks `isinstance(operation, AlterField)` and
`self.is_same_field_operation(operation)`. Under the claim precondition both are
true, so the method returns `[operation]`. This establishes K-001.

For PO-002, the returned list contains the same `operation` object passed to the
method. No new `AlterField` is constructed in this branch, so the later field
payload and `preserve_default` payload are preserved.

For PO-003 and PO-006, the branch condition includes
`self.is_same_field_operation(operation)`. That helper compares the same
normalized model and field keys used by the rest of the field optimizer. If
either key differs, the new branch is unreachable and execution falls through to
the pre-existing reducer logic. This establishes the frame claim K-003.

For PO-004, consider a finite chain of same-field alters
`[A1, A2, ..., An]` with `n >= 2`. PO-001 rewrites `[A1, A2]` to `[A2]`,
therefore the whole chain becomes `[A2, ..., An]`. The last operation `An` is
unchanged and the chain length decreases by one. By induction on `n`, repeated
optimizer passes terminate at `[An]`. The optimizer source supports this
induction because `optimize()` repeats `optimize_inner()` until the operations
list is unchanged, and each successful reduction returns an equal or shorter
list.

For PO-005, the new branch is type-disjoint from the existing `RemoveField` and
`RenameField` branches. Source order therefore cannot intercept those cases:
`RemoveField` is not an `AlterField`, and `RenameField` is not an `AlterField`.

For PO-007, the method signature and return protocol are unchanged. The
optimizer already treats any list result from `reduce()` as a replacement list,
so returning `[operation]` for this new case is contract-compatible.

## Machine-Check Commands

These commands are intentionally not executed in this environment:

```sh
kompile fvk/mini-migration-optimizer.k --backend haskell
kast --backend haskell fvk/alter-field-reduce-spec.k
kprove fvk/alter-field-reduce-spec.k
```

Expected result after a successful machine check: `kprove` returns `#Top` for
all claims.

## Test Redundancy Recommendation

No tests were modified or run. If the K claims are later machine-checked and
Django's normal tests pass, a focused optimizer regression test for the exact
same-field `AlterField` chain would be logically subsumed by PO-001 and PO-004.
Integration tests around migration writing, database schema editing, and
non-elidable migration boundaries should be kept because this proof abstracts
those systems away.

## Residual Risk

The proof is partial and constructed only. It models the optimizer-reducer
property, not every database backend side effect of applying migrations. That is
appropriate for this issue because the reported defect is the optimizer's
failure to reduce the operation list, but it means database integration tests
remain necessary.

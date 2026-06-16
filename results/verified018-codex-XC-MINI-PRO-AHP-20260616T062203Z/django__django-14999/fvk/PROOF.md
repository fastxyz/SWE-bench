# PROOF

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`, Python, or tests were run.

## Machine-Check Commands Not Executed

These are the commands to run in a future environment with K installed:

```sh
kompile fvk/mini-django-migrations.k --backend haskell
kast --backend haskell fvk/rename-model-spec.k
kprove fvk/rename-model-spec.k
```

Expected machine-check result, if the constructed proof is accepted: `#Top`.

## Proof Sketch

### PO-1 / `RENAME-MODEL-NOOP-SAME-TABLE`

Initial state:

`renameModelForwards(true, true, R, M)` with `R >= 0` and `M >= 0`.

The mini semantics applies the same-table rule:

`renameModelForwards(true, true, R, M) => done`

That rule does not rewrite `<dbops>`. The computation terminates at `done`; therefore the post-state has the same `<dbops>` value as the pre-state. This models V1 lines 323-332 returning before the table, relation, and M2M schema-editor calls.

### PO-2 / `RENAME-MODEL-NOOP-DISALLOWED`

Initial state:

`renameModelForwards(false, SameTable, R, M)` with non-negative counts.

The disallowed-migration rule rewrites directly to `done` and leaves `<dbops>` framed. This corresponds to the existing `allow_migrate_model()` guard enclosing the whole database branch.

### Helper Circularity / `RELATED-COUNT`

For `R = 0`, `emitRelated(0) => done` and `<dbops>` is unchanged, equal to adding `0`.

For `R > 0`, one rewrite step increments `<dbops>` by `1` and recurs on `emitRelated(R - 1)`. The circularity is guarded by that real rewrite step. The induction arithmetic is:

`1 + (R - 1) = R`

So the helper emits exactly `R` database operations for all `R >= 0`.

### Helper Circularity / `M2M-COUNT`

For `M = 0`, `emitM2M(0) => done` and `<dbops>` is unchanged, equal to adding `2 * 0`.

For `M > 0`, one rewrite step increments `<dbops>` by `2` and recurs on `emitM2M(M - 1)`. The circularity is guarded by that real rewrite step. The induction arithmetic is:

`2 + 2 * (M - 1) = 2 * M`

So the helper emits exactly `2 * M` database operations for all `M >= 0`.

### PO-3 / `RENAME-MODEL-DIFFERENT-TABLE-PRESERVES-WORK`

Initial state:

`renameModelForwards(true, false, R, M)` with non-negative counts.

The different-table rule rewrites to:

`emitRename ~> emitRelated(R) ~> emitM2M(M)`

`emitRename` increments `<dbops>` by `1`. By the helper circularities, `emitRelated(R)` increments by `R`, and `emitM2M(M)` increments by `2 * M`. By transitivity, the final increment is:

`1 + R + 2 * M`

This proves V1 preserves the different-table branch shape.

## Adequacy

`FORMAL_SPEC_ENGLISH.md` paraphrases each claim. `SPEC_AUDIT.md` checks each paraphrase against `INTENT_SPEC.md` and marks all pass. The proof therefore targets the public issue intent rather than the legacy side effects.

## Residual Risk

The proof abstracts concrete SQL and Django objects to a database-operation count. That abstraction is adequate for the reported bug because the intent is zero schema work on the same-table branch. It does not prove full SQL text, backend DDL behavior, or total correctness. It also remains constructed, not machine-checked.

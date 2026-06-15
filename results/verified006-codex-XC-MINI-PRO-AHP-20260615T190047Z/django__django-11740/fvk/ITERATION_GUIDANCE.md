# FVK Iteration Guidance

## Verdict

V1 stands unchanged. The FVK audit found that V1 satisfies the public-intent
obligation for the reported scalar-to-FK `AlterField` dependency bug and does
not justify further source edits.

## Decisions

- Keep the source change in `repo/django/db/migrations/autodetector.py`.
  Justification: FINDINGS F1 and PROOF_OBLIGATIONS PO1-PO3.
- Keep the broader relation-target condition rather than narrowing to
  "old field was not relational." Justification: FINDINGS F2 and
  PROOF_OBLIGATIONS PO1, PO2, PO4.
- Do not edit tests. Justification: FINDINGS F4 and PROOF_OBLIGATIONS PO7.
- Do not run tests or K tooling. Justification: FINDINGS F3 and
  PROOF_OBLIGATIONS PO7.

## Recommended Future Test

When test edits are allowed, add a migration autodetector test covering:

1. Old state: app `testapp1` has model `App1` with a nullable scalar UUID field.
2. New state: the same field is a nullable `ForeignKey` to `testapp2.App2`.
3. Expected operation: `AlterField`.
4. Expected dependency: the generated migration for `testapp1` depends on the
   latest migration for `testapp2` (or `__first__` when no graph leaf exists).

## Recommended Future Machine Check

In an environment with K installed, run:

```sh
kompile fvk/mini-autodetector.k --backend haskell
kast --backend haskell fvk/autodetector-spec.k
kprove fvk/autodetector-spec.k
```

Then run the relevant Django migration autodetector tests. Until that happens,
the proof remains constructed, not machine-checked.

## Next Code Iteration

No code iteration is recommended from this FVK pass. If a future audit broadens
the scope to simultaneous model renames plus relation alterations, audit that
path separately because `generate_altered_fields()` intentionally rewrites
relation targets during rename comparison.

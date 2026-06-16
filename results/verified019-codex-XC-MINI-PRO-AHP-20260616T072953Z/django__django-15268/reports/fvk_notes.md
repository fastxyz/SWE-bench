# FVK Notes

## Decisions

I revised V1 instead of leaving it unchanged because `fvk/FINDINGS.md` F-001 showed a parent-preservation gap: V1 returned `True` for cross `AlterUniqueTogether`/`AlterIndexTogether` operations before consulting inherited reducer behavior. `fvk/PROOF_OBLIGATIONS.md` PO-1 requires inherited non-`False` reductions to win. V2 now stores `result = super().reduce(operation, app_label)` and returns it whenever `result is not False`.

I kept the core V1 behavior that returns `True` for the other together option on the same model. F-002 is the original issue: the exact operation sequence in the public problem cannot collapse unless unique-together and index-together can optimize across each other. PO-2 states that transparency rule, and PO-4 constructs the optimizer trace from four operations down to the final two.

I kept the change scoped to `AlterTogetherOptionOperation` rather than broadening `ModelOptionOperation.reduce()`. F-003 and PO-5 require field-operation boundaries to remain intact, and PO-7 limits the new pass-through rule to the `AlterUniqueTogether`/`AlterIndexTogether` family named by the issue.

I did not modify the autodetector. The public symptom is an optimizer failure for operation sequences, and PO-4 is discharged by changing operation-level reduction behavior. The autodetector's split remove/add ordering remains available for cases with real field-operation boundaries.

I did not run tests, Python, or K tooling because the task forbids execution. F-004 records this as a proof capability gap, not a code bug. `fvk/PROOF.md` includes the commands that should be run later in an environment where K tooling is allowed.

## Files Changed

`repo/django/db/migrations/operations/models.py`

Added and then refined `AlterTogetherOptionOperation.reduce()`:

- parent reducer result is preserved first (F-001, PO-1);
- cross unique/index same-model operations return `True` only after inherited reduction fails (F-002, PO-2);
- all other cases return `False`, preserving boundaries (F-003, PO-5).

`fvk/`

Added the requested FVK artifacts plus a constructed mini K sketch:

- `SPEC.md`
- `FINDINGS.md`
- `PROOF_OBLIGATIONS.md`
- `PROOF.md`
- `ITERATION_GUIDANCE.md`
- `mini-migration-optimizer.k`
- `alter-together-reduce-spec.k`

These artifacts justify V2 and document the constructed, not machine-checked proof.

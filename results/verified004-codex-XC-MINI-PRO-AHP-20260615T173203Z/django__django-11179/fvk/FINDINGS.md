# FVK Findings

Status: constructed, not machine-checked.

## F1 - Resolved Code Bug: Optimized Instance Delete Did Not Clear PK

- Evidence: E1, E2, E3, E8.
- Proof obligations: PO1, PO2.
- Input: a saved fast-deletable model instance with `pk = P` and no dependencies.
- Pre-V1 observed behavior: the optimized branch returned immediately after `delete_batch()`, so the in-memory instance still had `pk = P`.
- Expected behavior: after successful `.delete()`, the in-memory instance primary key is `None`.
- V1 status: resolved by `repo/django/db/models/deletion.py`, where the optimized branch now calls `setattr(instance, model._meta.pk.attname, None)` after `delete_batch()` returns.

## F2 - Confirmed Non-Issue: Field Updates Need Not Be Duplicated in the Fast Branch

- Evidence: E5, E6.
- Proof obligations: PO3.
- Input: a model whose deletion would require `field_updates` through cascade/nulling behavior.
- Observed control flow: such a model is not eligible for `can_fast_delete(instance)`, so the optimized branch is not taken.
- Expected behavior: field updates remain handled by the normal collected-delete path.
- V1 status: no source change needed.

## F3 - Confirmed Frame: Public Delete API and Return Shape Are Preserved

- Evidence: E4, E7, E8.
- Proof obligations: PO4, PO5, PO6.
- Input: callers of `Model.delete()`, `QuerySet.delete()`, or internal `Collector.delete()`.
- Observed V1 behavior: method signatures and return values are unchanged; V1 adds only the in-memory instance PK side effect on the optimized successful instance-delete path.
- Expected behavior: public callers continue receiving the same delete result shapes while the affected instance state is corrected.
- V1 status: no additional source change needed.

## F4 - Residual Verification Risk: Constructed Proof Not Machine-Checked

- Evidence: FVK honesty gate and task constraint forbidding K tooling.
- Proof obligations: all.
- Input: the emitted K artifacts and commands.
- Observed state: the proof is constructed from static source reasoning but `kompile`/`kprove` were not executed.
- Expected next validation: run the commands in `fvk/PROOF.md` in an environment that has K installed.
- V1 status: not a code defect; keep tests until machine-checking and ordinary Django test execution are available.

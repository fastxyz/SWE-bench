# FVK Notes

## Decision

V1 stands unchanged. No additional production source edit is justified by the
FVK audit.

The decisive issue behavior is FINDINGS F-001: before V1, replacement
reconciliation was one-way, so a squashed migration row could remain present
after the replaced rows were removed. PROOF_OBLIGATIONS PO-003, PO-004, and
PO-006 discharge that issue for V1 by showing the new `not all_applied and key
in applied` branch removes the stale replacement row and composes with
`unapply_migration()`.

## Source Code

`repo/django/db/migrations/executor.py` was not changed during the FVK pass.

Reason: FINDINGS F-002 and PROOF_OBLIGATIONS PO-001, PO-002, and PO-007 show
that V1 preserves the existing apply-side reconciliation behavior. FINDINGS
F-005 and PO-008 show that V1 does not change public signatures, return types,
or caller protocols.

I considered moving the delete into `unapply_migration()`, but PO-006 shows that
the centralized reconciliation path already fixes the backward migrate behavior,
and PO-007 depends on keeping no-op/apply reconciliation in
`check_replacements()`.

I also considered updating the local `applied` snapshot while iterating
replacements. I left V1 unchanged because no finding or proof obligation
requires fixed-point reconciliation over nested replacement keys; FINDINGS F-001
and F-002 concern direct reconciliation against the entry recorder state.

## FVK Artifacts

I added the required artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

I also added the formal core requested by the FVK method:

- `fvk/mini-migrations.k`
- `fvk/migration-executor-spec.k`

The K artifacts use a set abstraction for `django_migrations`. That decision is
justified by FINDINGS F-003 and PO-005: the issue's observable is row
presence/absence by migration key, `applied_migrations()` exposes a dict keyed by
that migration key, and `record_unapplied()` deletes rows matching the key.

## Execution Limits

No tests, Python, `kompile`, `kast`, or `kprove` were run. This follows the task
instructions and is recorded in FINDINGS F-004 and PO-009. `fvk/PROOF.md` and
`fvk/ITERATION_GUIDANCE.md` include the commands and expected later outcome
without claiming any machine-checked result.

No test files were modified. The FVK proof is constructed, not machine-checked,
so FINDINGS F-004 and PO-009 also rule out recommending test deletion as part of
this pass.

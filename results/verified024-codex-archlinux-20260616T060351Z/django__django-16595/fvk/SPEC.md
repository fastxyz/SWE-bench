# FVK Specification

Status: constructed, not machine-checked. K artifacts are
`fvk/mini-migration-optimizer.k` and `fvk/alter-field-reduce-spec.k`.

## Scope

The audited production unit is `AlterField.reduce()` in
`repo/django/db/migrations/operations/fields.py`, with the optimizer behavior
in `repo/django/db/migrations/optimizer.py` used to reason about repeated
pairwise reductions. The proof models the reducer branch needed for this issue:
same-field `AlterField` followed by `AlterField`.

The model intentionally abstracts field internals as an opaque `Field` payload.
This is property-complete for the issue because the observable requirement is
which migration operation remains, and the later operation's whole payload is
retained.

## Intent Spec

IS-001: For a finite sequence of `AlterField` operations on the same model
field, the migration optimizer should reduce the sequence to the last
`AlterField` when no non-optimizable boundary prevents the reduction.

IS-002: The replacement operation must be the later `AlterField` operation,
preserving its model name, field name, field payload, and `preserve_default`
payload.

IS-003: The new reduction must be limited to same-model, same-field
`AlterField` pairs. Operations for different model/field keys must not be
collapsed by this new branch.

IS-004: Existing `AlterField` reductions for `RemoveField` and `RenameField`,
and existing fallback behavior through `FieldOperation.reduce()` and
`Operation.reduce()`, must remain unchanged.

IS-005: The public API and optimizer contract must remain compatible:
`reduce(self, operation, app_label)` keeps the same signature and returns either
a replacement list or the existing boolean-through/fallback result shape.

## Public Evidence Ledger

E-001, prompt: "Migration optimizer does not reduce multiple AlterField."
Obligation: encode IS-001.
Status: encoded in K claim `optimizeAlterChain(...) => last AlterField`.

E-002, prompt: "optimizer.optimize(operations[1:], \"books\")" returns three
`AlterField` operations.
Obligation: the detached AlterField chain is in scope; the absence of an
`AddField` must not prevent same-field AlterField reduction.
Status: encoded in IS-001 and finding F-001.

E-003, prompt: "AlterField.reduce does not consider the case where operation is
also an AlterField."
Obligation: the root cause is local to `AlterField.reduce()`.
Status: encoded in PO-001 and K claim `reduceAlter(...)`.

E-004, prompt/public hint: suggested branch returns `[operation]`.
Obligation: retain the later operation object as the replacement.
Status: encoded in IS-002 and PO-002.

E-005, code: `is_same_field_operation()` compares lower-case model and field
names.
Obligation: same-field matching uses the existing operation helper rather than a
new comparison.
Status: encoded in IS-003 and PO-003.

E-006, code: `MigrationOptimizer.optimize()` repeats `optimize_inner()` until
the result is unchanged.
Obligation: a pairwise reduction is enough to collapse finite chains.
Status: encoded in PO-004 and the chain K claim.

E-007, code: `AlterField.reduce()` already handles `RemoveField` and
`RenameField` specially.
Obligation: the new branch must not change these cases.
Status: encoded in IS-004 and PO-005.

## Formal Spec English

K-001: For any normalized model key `M`, field key `N`, fields `F1/F2`, and
preserve-default flags `P1/P2`, reducing
`alter(M, N, F1, P1)` against `alter(M, N, F2, P2)` reaches
`ops(alter(M, N, F2, P2))`.

K-002: For any three consecutive same-field `AlterField` operations, repeated
optimization reaches a one-operation list containing the third operation.

K-003: For two `AlterField` operations whose normalized model/field keys differ,
the new same-field branch does not reduce them and the modeled result is the
fallback marker `pass(false)`.

## Spec Audit

K-001 passes: it is directly entailed by E-003 and E-004.

K-002 passes: it combines E-001, E-002, and E-006. The formal claim uses three
operations because the issue example contains three detached `AlterField`
operations; the proof obligation PO-004 generalizes it to finite chains by the
optimizer's decreasing length measure.

K-003 passes: it is a frame condition derived from E-005. It prevents the proof
from certifying an over-broad branch.

No formal-English obligation is candidate-derived without public or source
evidence. No legacy pre-fix output is used as an oracle; the issue's displayed
three-operation output is recorded as the buggy behavior.

## Public Compatibility Audit

Changed symbol: `AlterField.reduce(self, operation, app_label)`.

Compatibility result: pass. The method signature is unchanged, no public call
site changes are required, and the returned type remains the optimizer's
existing replacement-list shape. The only newly returned list occurs for the
same-field `AlterField` pair identified by the issue.

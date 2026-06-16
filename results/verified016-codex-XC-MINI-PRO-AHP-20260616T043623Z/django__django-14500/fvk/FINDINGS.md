# FVK Findings

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## F-001: Closed code bug, one-way replacement reconciliation

Evidence: `SPEC.md` entries E-001, E-002, E-004, E-005, and E-006.

Input/state: a replacement migration key `k` is present in `django_migrations`;
then unapplying `k` removes all rows in `R(k)` but leaves `k`'s own row present
until replacement reconciliation runs.

Observed in pre-V1 code: `check_replacements()` only added missing replacement
rows when all replaced rows were applied. It did not remove `k` when the replaced
set was no longer fully applied.

Expected: `k` is absent after the migrate run because not all rows in `R(k)` are
present.

Resolution: V1 adds the missing branch:
`elif not all_applied and key in applied: record_unapplied(*key)`.

Related proof obligations: PO-003, PO-004, and PO-006.

## F-002: V1 preserves apply-side replacement reconciliation

Evidence: `SPEC.md` entries E-003, E-005, and E-007.

Input/state: all rows in `R(k)` are present.

Observed in V1: if `k` is absent, `check_replacements()` records it as applied;
if `k` is present, it leaves it present.

Expected: `k` is present.

Resolution: no further code change required. The V1 branch is additive and does
not alter the existing all-applied branch.

Related proof obligations: PO-001, PO-002, and PO-007.

## F-003: Set abstraction for recorder rows is adequate for this issue

Evidence: `SPEC.md` entries E-006 and the implementation of
`MigrationRecorder.applied_migrations()` and `record_unapplied()`.

Input/state: `django_migrations` is represented as the set of keys returned by
`applied_migrations()`.

Observed: Django exposes applied migrations through a dict keyed by `(app,
name)`, and `record_unapplied()` deletes rows matching `(app, name)`.

Expected for this issue: row presence or absence, not row multiplicity, is the
observable applied/unapplied state.

Resolution: no source change required. Duplicate physical rows are outside this
issue's observable and are collapsed by the public recorder read API.

Related proof obligations: PO-005 and PO-008.

## F-004: Constructed proof was not machine-checked

Evidence: task instructions forbid running tests, Python, `kompile`, or
`kprove`.

Input/state: FVK proof artifacts exist but are not executed.

Observed: no machine result such as `#Top` is available.

Expected: artifacts must include the commands and expected outcome for a later
environment.

Resolution: `PROOF.md` and `ITERATION_GUIDANCE.md` include the exact commands
that should be run later. No test deletion or machine-checked confidence is
claimed.

Related proof obligations: PO-009.

## F-005: No blocking compatibility finding

Evidence: `SPEC.md` public compatibility audit.

Input/state: public callers and overrides of the changed symbol.

Observed in V1: no signature, return type, call protocol, or data shape changed.

Expected: public compatibility preserved.

Resolution: no code change required.

Related proof obligations: PO-008.

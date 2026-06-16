# FVK Proof Obligations

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## PO-001: Forward add missing replacement row

Claim: for replacement key `k`, if all keys in `R(k)` are in the entry applied
set `A` and `k` is not in `A`, then `k` is in the post-state.

Source: SPEC C-001.

Status: discharged by static case analysis. V1's first branch records `k` as
applied when `all_applied` is true and `key not in applied`.

## PO-002: Forward preserve existing replacement row

Claim: if all keys in `R(k)` are in `A` and `k` is already in `A`, then `k`
remains in the post-state.

Source: SPEC C-002.

Status: discharged by static case analysis. V1 performs no delete in the
`all_applied` branch.

## PO-003: Backward remove stale replacement row

Claim: if at least one key in `R(k)` is missing from `A` and `k` is in `A`, then
`k` is absent from the post-state.

Source: SPEC C-003 and FINDINGS F-001.

Status: discharged by static case analysis. V1's new `elif` records `k` as
unapplied when `not all_applied` and `key in applied`.

## PO-004: Backward preserve absent replacement row

Claim: if at least one key in `R(k)` is missing from `A` and `k` is not in `A`,
then `k` remains absent.

Source: SPEC C-004 and FINDINGS F-001.

Status: discharged by static case analysis. V1 performs no write in this case.

## PO-005: Frame unrelated recorder keys

Claim: for any key `x` that is not a replacement key in
`self.loader.replacements`, `x in A'` iff `x in A`.

Source: SPEC C-005 and FINDINGS F-003.

Status: discharged by code inspection. V1 only calls recorder methods with
replacement keys from `self.loader.replacements`; replaced target keys and other
unrelated keys are not modified by `check_replacements()`.

## PO-006: Unapply composition

Claim: after `unapply_migration()` runs for a replacement migration `k`, the
subsequent `check_replacements()` call in `migrate()` leaves `k` absent.

Source: SPEC C-006 and FINDINGS F-001.

Status: discharged by composition. `unapply_migration()` removes every row in
`R(k)`. Since `R(k)` is non-empty for loaded replacements, `all_applied` is false
at the following reconciliation, and PO-003 or PO-004 leaves `k` absent.

## PO-007: Apply and no-op composition

Claim: if every key in `R(k)` is present before reconciliation, then
`check_replacements()` leaves `k` present, including no-op migrate runs.

Source: SPEC C-007 and FINDINGS F-002.

Status: discharged by PO-001 and PO-002. This preserves the existing
apply-side behavior.

## PO-008: Public compatibility

Claim: V1 does not change public signatures, return types, virtual dispatch
requirements, or recorder data shape.

Source: SPEC C-008 and FINDINGS F-005.

Status: discharged by diff inspection. Only an internal branch and docstring in
`check_replacements()` changed.

## PO-009: Honesty gate

Claim: the audit must not claim machine-checked proof results, test results, or
test-removal safety.

Source: FINDINGS F-004 and task instructions.

Status: discharged by artifact content. Commands are written for later use, but
no executed result is claimed.

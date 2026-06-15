# FVK Spec

Status: constructed, not machine-checked.

## Target

Audit target: `repo/django/core/cache/backends/db.py`, specifically `DatabaseCache._cull()` and the `_base_set()` call path that invokes it during database cache writes.

## Intent Summary

The public issue reports that `_cull()` can raise `'NoneType' object is not subscriptable` because `cursor.fetchone()` after `connection.ops.cache_key_culling_sql()` returns no row. The intended behavior is not to expose cache-maintenance failures during culling when the cutoff row is missing.

The public docs also define the culling ratio: `CULL_FREQUENCY` culls a fraction `1 / CULL_FREQUENCY`, while `0` dumps the whole cache. Therefore frequency `1` means all current rows are culled.

## Evidence and Adequacy Artifacts

The intent-only spec is in `fvk/INTENT_SPEC.md`.
The public evidence ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`.
The formal claims are paraphrased in `fvk/FORMAL_SPEC_ENGLISH.md`.
The adequacy comparison is in `fvk/SPEC_AUDIT.md`.
The compatibility audit is in `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.

## Formal Core

The mini semantics is in `fvk/mini-cache-cull.k`.
The K claims are in `fvk/database-cache-cull-spec.k`.

The model abstracts rows already expired by `now` as removed before culling, then represents the remaining table by:

- `NUM`: the post-expiry row count.
- `MAX`: the configured `MAX_ENTRIES`.
- `FREQ`: the configured `CULL_FREQUENCY`.
- `Cutoff`: `some(key)` if the backend cutoff query returns a row, or `none` if it returns no row.

This abstraction keeps the defect-observable property: whether the no-row cutoff path can reach a TypeError. It also keeps the culling-ratio property that distinguishes normal culling from frequency-one full culling.

## Preconditions and Assumptions

P-001. `NUM >= 0`.

P-002. `FREQ` is in the documented domain: `0` or a positive integer.

P-003. Cache keys are unique, non-null strings, as created by `createcachetable`.

P-004. For stable tables, backend cutoff SQL returns the first key greater than the `cull_num` smallest keys when that offset exists, and no row when it does not.

## Postconditions

S-001. Missing cutoff row: for `FREQ > 0`, `NUM > MAX`, and `Cutoff = none`, `_cull()` does not index a missing row and leaves cutoff deletion skipped for this attempt.

S-002. Frequency one: for `FREQ = 1` and `NUM > MAX`, `_cull()` deletes all current rows directly instead of selecting a cutoff at offset `NUM`.

S-003. Ordinary cutoff: for `FREQ > 0`, `NUM > MAX`, and `Cutoff = some(key)`, `_cull()` preserves the existing cutoff-delete behavior.

S-004. Zero frequency: for `FREQ = 0`, `_cull()` preserves the full-cache dump behavior.

S-005. Below limit: for `NUM <= MAX`, no cutoff delete is performed.

## Spec Verdict

V1 satisfies the intent spec. No source change beyond V1 is required by the FVK audit.

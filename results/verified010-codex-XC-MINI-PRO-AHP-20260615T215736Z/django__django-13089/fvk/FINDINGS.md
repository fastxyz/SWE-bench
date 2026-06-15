# FVK Findings

Status: constructed, not machine-checked.

## F-001: Missing Cutoff Row

Classification: resolved code bug.

Evidence: the public issue says the cutoff query may return no data and that `cursor.fetchone()[0]` then fails with `'NoneType' object is not subscriptable`.

Input/state: `FREQ > 0`, `NUM > MAX`, `cull_num != NUM`, and cutoff query result is `None`.

V0 observed: `_cull()` indexed `cursor.fetchone()[0]`, causing a TypeError.

V1 observed by source inspection: `_cull()` stores `cull_key = cursor.fetchone()` and only indexes it when `cull_key is not None`.

Expected: no TypeError from a missing cutoff row. The cull attempt may skip cutoff deletion and a later write can retry.

Trace: PO-001.

## F-002: Frequency-One Offset Past End

Classification: resolved boundary bug.

Evidence: docs define the culling ratio as `1 / CULL_FREQUENCY`. When `CULL_FREQUENCY` is `1`, the intended cull count is all current rows. V0 computed `cull_num = num` and asked the database for offset `num`, which has no row.

Input/state: `FREQ = 1`, `NUM > MAX`.

V0 observed: cutoff query has no row, then `fetchone()[0]` can fail.

V1 observed by source inspection: `cull_num == num` triggers `DELETE FROM table`, so no cutoff row is required.

Expected: all current rows are removed.

Trace: PO-002.

## F-003: Normal Culling Must Not Regress

Classification: confirmed preserved behavior.

Evidence: backend operation docs define cutoff SQL as selecting the first key greater than the `n` smallest keys.

Input/state: `FREQ > 0`, `NUM > MAX`, `cull_num != NUM`, cutoff query returns a row.

V1 observed by source inspection: the existing cutoff SQL and `DELETE ... WHERE cache_key < %s` are still used.

Expected: preserve the previous normal cutoff-delete strategy.

Trace: PO-003.

## F-004: Negative Cull Frequency Is Outside Public Intent

Classification: underspecified intent, no code change.

Evidence: docs say `CULL_FREQUENCY` is an integer fraction and only define special behavior for `0`. They do not define negative values.

Input/state: `FREQ < 0`.

Observed: `_cull()` would compute a negative offset path, which is outside the FVK proof domain.

Expected: no conclusion for this issue. A separate hardening task could validate or reject negative cache options, but the public issue does not require it.

Trace: PO-006.

## F-005: Full Database Concurrency Is An Escalation Boundary

Classification: proof capability gap, not a source bug in V1.

Evidence: the reported failure is sporadic and can arise from database state changing between count and cutoff selection. The mini semantics abstracts that by allowing `Cutoff = none`.

Input/state: concurrent database mutation around `_cull()`.

Observed: the constructed proof covers the no-row observable. It does not model transaction isolation, router behavior, or backend-specific cursor semantics in full.

Expected: keep integration and backend tests. Do not remove tests based on this constructed proof alone.

Trace: PO-007.

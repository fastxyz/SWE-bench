# Proof Obligations

Status: constructed, not machine-checked.

## PO-001: Missing Cutoff Row Safety

Claim: if `FREQ > 0`, `NUM > MAX`, `NUM / FREQ != NUM`, and cutoff query returns no row, `_cull()` completes the culling branch without indexing into `None`.

Formal claim: `cull(FREQ, MAX, NUM, none) => rows(NUM)`.

Discharged by V1 source: `cull_key = cursor.fetchone()` followed by `if cull_key is not None:` before `cull_key[0]`.

Finding trace: F-001.

## PO-002: Frequency-One Full Cull

Claim: if `FREQ = 1` and `NUM > MAX`, all current rows are removed without selecting a cutoff row.

Formal claim: `cull(1, MAX, NUM, CUTOFF) => rows(0)`.

Discharged by V1 source: `cull_num = num // self._cull_frequency`; for frequency one, `cull_num == num`, so `_cull()` executes `DELETE FROM table`.

Finding trace: F-002.

## PO-003: Present Cutoff Preserves Existing Behavior

Claim: if a cutoff row exists and the cull count is not the full table, `_cull()` still deletes keys before the returned cutoff.

Formal claim: `cull(FREQ, MAX, NUM, some(CUTOFF)) => rows(NUM - NUM / FREQ)`.

Discharged by V1 source: the existing `connection.ops.cache_key_culling_sql()` call and `DELETE ... WHERE cache_key < %s` remain in the `else` branch.

Finding trace: F-003.

## PO-004: Zero Frequency Frame

Claim: if `FREQ = 0`, `_cull()` preserves documented behavior and clears the cache.

Formal claim: `cull(0, MAX, NUM, CUTOFF) => rows(0)`.

Discharged by V1 source: the pre-existing `if self._cull_frequency == 0: self.clear()` branch is unchanged.

Finding trace: none, preserved frame condition.

## PO-005: Below-Limit Frame

Claim: if post-expiry `NUM <= MAX`, no cutoff culling is performed.

Formal claim: `cull(FREQ, MAX, NUM, CUTOFF) => rows(NUM)`.

Discharged by V1 source: cutoff selection remains inside `if num > self._max_entries:`.

Finding trace: none, preserved frame condition.

## PO-006: Domain Assumptions

Claim: proof assumes `FREQ >= 0`, `NUM >= 0`, non-null ordered cache keys, and backend cutoff SQL returning either one row or no row.

Discharged by public evidence: cache docs define zero and positive fraction behavior; `createcachetable` defines `cache_key` as a primary key; backend operations define the cutoff SQL purpose.

Finding trace: F-004.

## PO-007: Escalation Boundary

Claim: the constructed proof abstracts database concurrency to the observable `Cutoff = none`; it does not prove full transaction, isolation, or cursor semantics.

Consequence: keep relevant backend/integration tests until actual `kprove` and conventional tests are available.

Finding trace: F-005.

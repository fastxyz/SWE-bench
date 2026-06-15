# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`, tests, Python, or project code were run.

## Claims Proved in the Model

The proof covers the abstract culling command in `fvk/mini-cache-cull.k` and the claims in `fvk/database-cache-cull-spec.k`.

1. Missing cutoff row: `cull(FREQ, MAX, NUM, none) => rows(NUM)` under `FREQ > 0`, `NUM > MAX`, and `NUM / FREQ != NUM`.
2. Frequency one: `cull(1, MAX, NUM, CUTOFF) => rows(0)` under `NUM > MAX`.
3. Present cutoff row: `cull(FREQ, MAX, NUM, some(CUTOFF)) => rows(NUM - NUM / FREQ)` under `FREQ > 0`, `NUM > MAX`, and `NUM / FREQ != NUM`.
4. Zero frequency: `cull(0, MAX, NUM, CUTOFF) => rows(0)`.
5. Below limit: `cull(FREQ, MAX, NUM, CUTOFF) => rows(NUM)` under `FREQ > 0` and `NUM <= MAX`.

## Symbolic Execution Sketch

The mini semantics has one rewrite rule per culling branch.

For claim 1, the side condition matches the `none` rule. The result is `rows(NUM)`. No rule rewrites to `typeError`, and the `none` rule has no operation corresponding to indexing a missing row. This maps to the V1 guard `if cull_key is not None`.

For claim 2, with `FREQ = 1`, `cullNum(NUM, 1) = NUM /Int 1 = NUM`. The side condition matches the all-rows rule and reaches `rows(0)`. This maps to the V1 branch `if cull_num == num: DELETE FROM table`.

For claim 3, a present cutoff matches the `some(CUTOFF)` rule and reaches `rows(NUM - cullNum(NUM, FREQ))`. This preserves the existing cutoff-delete behavior.

For claim 4, frequency zero matches the zero-frequency rule and reaches `rows(0)`, preserving `self.clear()`.

For claim 5, `NUM <= MAX` matches the no-cull rule and reaches `rows(NUM)`, preserving the existing branch guard.

## Proof Obligations Closed by Source Inspection

PO-001 is closed by the `None` guard before `cull_key[0]`.

PO-002 is closed by the all-rows delete branch when `cull_num == num`.

PO-003 is closed because the existing backend cutoff SQL and cutoff delete remain unchanged for present cutoff rows.

PO-004 and PO-005 are frame conditions over unchanged branches.

PO-006 and PO-007 are explicit domain and escalation boundaries, not code obligations for this issue.

## Adequacy Result

`fvk/SPEC_AUDIT.md` marks all required issue and docs-derived behaviors as pass. The only ambiguous item is negative `CULL_FREQUENCY`, which is outside the public issue and outside the documented fraction domain.

## Machine Check Commands

These commands are emitted for later machine checking and were not run:

```sh
kompile fvk/mini-cache-cull.k --backend haskell
kast --backend haskell fvk/database-cache-cull-spec.k
kprove fvk/database-cache-cull-spec.k
```

Expected result after a successful machine check: `#Top`.

## Test Redundancy

No test removal is recommended. The proof is constructed but not machine-checked, and PO-007 leaves full database and concurrency behavior to conventional backend/integration tests.

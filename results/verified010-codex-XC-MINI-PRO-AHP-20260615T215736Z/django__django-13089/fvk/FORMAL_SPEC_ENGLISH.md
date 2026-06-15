# Formal Spec English

Status: constructed, not machine-checked.

The formal model is `fvk/mini-cache-cull.k`; the claims are in `fvk/database-cache-cull-spec.k`. The model abstracts the table after expired-row deletion to `NUM`, the current row count, and abstracts the cutoff query to `some(key)` or `none`.

C-001. For positive `FREQ`, `NUM > MAX`, and cutoff `none`, `cull(FREQ, MAX, NUM, none)` reaches `rows(NUM)`. In words: missing cutoff rows do not crash and do not delete by a fabricated cutoff.

C-002. For `FREQ = 1` and `NUM > MAX`, `cull(1, MAX, NUM, cutoff)` reaches `rows(0)`. In words: cull frequency one clears all current rows without consulting the cutoff row.

C-003. For positive `FREQ`, `NUM > MAX`, and cutoff `some(key)`, `cull(FREQ, MAX, NUM, some(key))` reaches `rows(NUM - NUM / FREQ)`. In words: ordinary culling with a cutoff preserves the existing ratio-based deletion count.

C-004. For `FREQ = 0`, `cull(0, MAX, NUM, cutoff)` reaches `rows(0)`. In words: zero frequency dumps the cache.

C-005. For positive `FREQ` and `NUM <= MAX`, `cull(FREQ, MAX, NUM, cutoff)` reaches `rows(NUM)`. In words: no cutoff culling occurs when the post-expiry count is within the limit.

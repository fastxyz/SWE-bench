# Spec Audit

Status: constructed, not machine-checked.

| Formal item | Intent item | Verdict | Notes |
|---|---|---|---|
| C1 sliced inverse correctness | INTENT 1, E1, E2 | PASS | The claim states the exact on-slice inverse behavior requested by the issue. |
| C2 fixed dropped world values | INTENT 2, E3 | PASS | The claim directly replaces the placeholder behavior identified as wrong. |
| C3 metadata consistency | INTENT 5, E7 | PASS | Uses existing metadata semantics as supporting public evidence without preserving the bug. |
| Coordinate order frame | INTENT 3, E4, E5 | PASS | Formal spec preserves `_world_keep` input order and `_pixel_keep` output order. |
| Range-slice starts | INTENT 4, existing source behavior | PASS | This is a frame condition over behavior not implicated by the bug. |
| Return shape and signatures | INTENT 6, E4 | PASS | No public signature or return convention changed. |
| No transform-state cache | INTENT 6, compatibility audit | PASS | The public intent does not require caching; recomputing fixed world values avoids a new implementation-derived dependency. |
| Full FITS WCS numerical semantics | Domain assumptions | AMBIGUOUS / OUT OF SCOPE | The abstract proof assumes the wrapped WCS inverse contract; it does not prove wcslib/FITS numerical behavior. This is recorded as proof capability finding F3. |

No formal claim is derived solely from the V1 implementation. The only
candidate-derived observation was the V1 cache, and the audit rejected it as
unnecessary for the intent.

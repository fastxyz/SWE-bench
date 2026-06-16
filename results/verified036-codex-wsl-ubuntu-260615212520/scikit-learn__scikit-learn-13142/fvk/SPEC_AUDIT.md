# Spec Audit

Status: adequacy gate for the constructed claims.

| Formal item | Intent item | Result | Notes |
| --- | --- | --- | --- |
| FIT-PREDICT-CONSISTENCY | I1, I2, I3 | pass | It states labels are computed from `bestParams(RS)`, matching the issue and docstring. |
| SELECT-BEST-CIRCULARITY | I2 | pass | It captures the best-lower-bound invariant required by the docstring. |
| ARGMAX-RESP-PREDICT | I1, I3 | pass | It proves equality from shared parameter state and row-wise argmax invariance. |
| PUBLIC-FRAME | I4, I5 | pass | It does not preserve the legacy pre-restore label behavior; it preserves only public API and non-label frame behavior. |
| Domain assumptions | I6, I7 | pass with boundary | Full EM numeric correctness is explicitly outside this issue; the consistency property remains in scope. |

No claim is candidate-only or legacy-derived. The one legacy behavior from V0
that returned labels from the last initialization is marked as the resolved bug
in `FINDINGS.md`, not preserved as a frame condition.

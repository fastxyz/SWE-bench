# Spec Audit

Status: constructed, not machine-checked.

| Formal item | Intent coverage | Result |
| --- | --- | --- |
| `SFS-SCORE-LOOP` | E2, E3, E8 require repeated candidate scoring to see reusable splits. | Pass |
| `SFS-FIT-ONESHOT` | E1, E2, E4 require one-shot split generators to work in one fit via `check_cv`. | Pass |
| `SFS-FIT-ITERABLE` | E5, E6, E7 require iterable CV inputs to remain accepted. | Pass |
| `SFS-FIT-SPLITTER` | E5 and the docstring include CV splitter objects; V1 must preserve them. | Pass |
| `SFS-FIT-INT` | E5 and the docstring include integer CV values; V1 must preserve them. | Pass |
| `SFS-FIT-NONE` | `check_cv` public behavior maps `None` to five folds; frame condition preserves it. | Pass |
| `SFS-RAW-ONESHOT-FAILS` | E3 describes the legacy failure mechanism. | Pass as finding/localization only |

## Adequacy Notes

- The formal model is narrower than full Python/scikit-learn, but it preserves
  the observable defect axis: whether repeated candidate scoring consumes the
  same one-shot CV iterable.
- The model does not prove estimator fitting, scoring correctness, feature
  ranking, or total termination. Those are outside the issue-specific intent and
  are recorded as residual risk, not as proof of correctness.
- No claim relies on current V1 behavior alone. Each behavior needed to confirm
  V1 traces to public issue text, docstring/API evidence, or existing
  `check_cv`/`cross_val_score` contracts.

# Spec Audit

All entries are constructed, not machine-checked.

| Formal item | Intent item | Result | Notes |
| --- | --- | --- | --- |
| `GET-FORWARDS-RAW-KWARGS` | I1, I2 | Pass | Directly covers the reported regression. |
| `GET-RENDERS-WRAPPED-CONTEXT` | I3, I4 | Pass | Preserves transitional final context behavior. |
| `wrapCtx` unchanged-entry rule | I4 | Pass | Models the delayed warning wrapper. |
| `wrapCtx` removed/replaced frame rule | I5 | Pass | Prevents overwriting override decisions. |
| No ORM claim | I6 | Pass | Matches public hint that ORM lazy support is not the regression. |
| Mapping-return assumption | Context contract | Pass with boundary | Arbitrary non-mapping custom returns are outside the documented context contract. |

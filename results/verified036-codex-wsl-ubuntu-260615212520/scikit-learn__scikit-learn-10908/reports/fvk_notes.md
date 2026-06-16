# FVK Notes

Status: constructed, not machine-checked.

I kept the V1 source code unchanged. The core decision traces to F-001 and PO-001: the V1 guard in `CountVectorizer.get_feature_names()` invokes `_validate_vocabulary()` when `vocabulary_` is absent, which discharges the public issue requirement that a valid constructor vocabulary should allow feature names before fitting.

I did not broaden the change into `_check_vocabulary()`. F-002/PO-002 and F-005/PO-005 show the existing materialized-vocabulary path and public caller protocol are already preserved, while `ITERATION_GUIDANCE.md` records that changing `_check_vocabulary()` would affect other callers such as `inverse_transform()` without public evidence.

I did not move validation into `__init__`. F-001/PO-001 tie the fix to lazy materialization, and E-003 identifies the existing `transform()` path as the public repair model. Constructor-time validation would be a broader lifecycle change than the proof obligations require.

I did not add a special no-vocabulary guard beyond V1. F-003 and PO-003 require only that an unfitted vectorizer without a constructor vocabulary continues to raise `NotFittedError`; the proof does not rely on any public guarantee about side effects on that error path.

I did not modify tests. F-006 records that no tests, Python, or K tooling were run, and the task forbids test-file edits. All test removal or redundancy decisions are deferred until the constructed K proof can be machine-checked.


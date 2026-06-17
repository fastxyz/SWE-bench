# FVK Notes

Decision: V1 stands unchanged.

The audit found that the public issue intent is covered by V1. `fvk/FINDINGS.md` F1 identifies the original failure mode, and `fvk/PROOF_OBLIGATIONS.md` O1/O2 show that the new `Contains.as_set()` branch reaches `ConditionSet(x, Contains(x, set))` and then the existing `ConditionSet` flattening rule returns the member set. This justifies keeping the V1 `Contains.as_set()` implementation.

The generic Boolean change is also kept. `fvk/FINDINGS.md` F3 and `fvk/PROOF_OBLIGATIONS.md` O3 trace the public hint about one-free-variable Boolean `as_set()` to the new `Boolean._eval_as_set()` fallback returning `ConditionSet(symbol, boolean)`.

I did not edit the stale visible test or preserve its expected `NotImplementedError`. `fvk/FINDINGS.md` F2 classifies that expectation as SUSPECT legacy behavior because it conflicts with the public issue hint that `Contains(x, set).as_set()` should return `set`. The task also forbids modifying tests.

I did not broaden the implementation to multivariate Boolean conversion. `fvk/FINDINGS.md` F4 and `fvk/PROOF_OBLIGATIONS.md` O6 record that the public hint explicitly leaves multivariate behavior unimplemented and uncertain, so preserving the existing `NotImplementedError` boundary is intentional.

No tests, Python, or K tooling were run. `fvk/FINDINGS.md` F5 and `fvk/PROOF_OBLIGATIONS.md` O7 record the constructed-not-machine-checked caveat and list the proof commands only as future reproduction steps.

# FVK Findings

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## F-001: V0 target-state lookup used the wrong model key

Classification: code bug, fixed by V1.

Input shape: app `A`, old model name `O`, new model name `N`, accepted model
rename `O -> N`, and a field rename on the same model in the same autodetection
pass. The target state contains `to_state.models[(A, N)]` and no
`to_state.models[(A, O)]`.

Observed in V0: `generate_renamed_fields()` computed `old_model_name = O` and
then evaluated `self.to_state.models[(A, O)]`, raising `KeyError`.

Expected from intent: field rename detection should read the target model from
`to_state.models[(A, N)]` and continue without that `KeyError`.

Trace:

- Evidence: `SPEC.md` E-001 and E-002.
- Obligations: `PROOF_OBLIGATIONS.md` O-001, O-002, O-003, O-004.
- Proof: `PROOF.md` P-003 and P-004.

Resolution: V1 changes the target-state lookup to
`self.to_state.models[app_label, model_name]`. No additional code change is
justified by this finding.

## F-002: V1 preserves the old/new state-key split

Classification: positive proof finding.

Input shape: same as F-001.

Observed in V1: `old_model_name` is used only for the historical
`from_state` lookup, while `model_name` is used for the target `to_state`
lookup.

Expected from intent and implementation invariants: after a model rename,
historical fields come from `(A, O)` and target fields come from `(A, N)`.

Trace:

- Evidence: `SPEC.md` E-003 through E-007.
- Obligations: `PROOF_OBLIGATIONS.md` O-001, O-002, O-004.
- Proof: `PROOF.md` P-001, P-002, P-004.

Resolution: V1 is confirmed for the reported state-key defect.

## F-003: Non-renamed model behavior is unchanged

Classification: frame condition, confirmed.

Input shape: no model rename entry for `(A, M)`.

Observed in V1: `old_model_name = self.renamed_models.get((A, M), M)` evaluates
to `M`, and the target-state lookup is `self.to_state.models[(A, M)]`.

Expected from frame condition: field rename detection for non-renamed models
continues using the same model key as before.

Trace:

- Evidence: `SPEC.md` E-007 and FSE-005.
- Obligation: `PROOF_OBLIGATIONS.md` O-005.
- Proof: `PROOF.md` P-005.

Resolution: no further source change.

## F-004: Full Django migration generation remains outside the focused proof

Classification: proof capability boundary, not a code bug.

Input shape: arbitrary Django project states with relations, through models,
constraints, operation dependencies, questioner policies, and graph arranging.

Observed in this FVK pass: the constructed K model covers the state-key
property that produces the reported crash. It does not model all Django
autodetector behavior.

Expected from FVK honesty gate: the proof must be labeled constructed, not
machine-checked, and the abstraction boundary must be explicit.

Trace:

- Evidence: `SPEC.md` Scope and Formal Artifacts.
- Obligation: `PROOF_OBLIGATIONS.md` O-006.
- Proof: `PROOF.md` Residual Risk.

Resolution: keep existing project tests; no test removal is recommended. This
boundary does not justify changing V1 because no uncovered public-intent
obligation contradicts the V1 lookup fix.

## Proof-derived findings from verify

No additional code bug was derived during proof construction. The only
counterexample constructed is the V0 lookup `to_state[(A, O)]`, which V1
removes. The remaining open item is the proof capability boundary in F-004.

# FVK Notes

The FVK audit confirmed the V1 source fix and did not justify further
production-code edits. This decision traces to `fvk/FINDINGS.md` and
`fvk/PROOF_OBLIGATIONS.md` as follows.

## Decisions

Kept the public `fill_value` constructor parameter unchanged.

- Basis: F-001 and O-001.
- Reason: public intent requires a `fill_value` parameter, and V1 stores it as
  `self.fill_value`, making it part of estimator parameter introspection.

Kept the internal `SimpleImputer(..., fill_value=self.fill_value)` forwarding
unchanged.

- Basis: F-002 and O-002.
- Reason: the quoted `SimpleImputer` behavior is the required mechanism for
  constant initialization, and V1 forwards the exact stored value.

Kept the constant-strategy validity-mask branch unchanged.

- Basis: F-003 and O-003.
- Reason: without this branch, `fill_value=np.nan` would be indistinguishable
  from an invalid statistic and could drop every feature before a NaN-capable
  estimator can run.

Kept non-constant strategy behavior unchanged.

- Basis: F-004 and O-004.
- Reason: the issue only requires `fill_value` behavior for
  `initial_strategy="constant"`; V1 preserves the previous non-NaN statistic
  filtering for other strategies.

Kept the default `fill_value=None`.

- Basis: O-005.
- Reason: preserving `None` delegates default constant selection to
  `SimpleImputer`, which is the compatibility-preserving behavior.

Did not implement `SimpleImputer` instances as `initial_strategy`.

- Basis: intent item I-006 in `fvk/INTENT_SPEC.md` and E-007 in
  `fvk/PUBLIC_EVIDENCE_LEDGER.md`.
- Reason: the public issue discussion identifies that as a broader future API
  idea; the requested fix is adding `fill_value`.

## Execution Constraint

No tests, Python imports, or K commands were run. The FVK proof is constructed
and the commands to machine-check it later are recorded in `fvk/PROOF.md` and
`fvk/PROOF_OBLIGATIONS.md`.

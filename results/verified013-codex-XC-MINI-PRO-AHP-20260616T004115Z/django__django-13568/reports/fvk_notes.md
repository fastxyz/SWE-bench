# FVK Notes

The FVK audit confirmed V1 without additional source edits.

## Decisions

D1. Keep the V1 source predicate unchanged.

Trace: `fvk/FINDINGS.md` F1 confirms the reported
`UniqueConstraint(fields=["username"])` case is covered. `fvk/PROOF_OBLIGATIONS.md`
PO1 defines the accepted uniqueness predicate, and PO3 shows the concrete issue
case skips both `auth.E003` and `auth.W004`.

D2. Keep exact tuple equality, not a looser membership check.

Trace: F4 shows a composite constraint such as `("username", "tenant")` would
not make `username` globally unique. PO6 requires excluding such composite
constraints, and V1 discharges that obligation by checking
`constraint.fields == (cls.USERNAME_FIELD,)`.

D3. Keep `_meta.total_unique_constraints` as the source of model-level
constraints.

Trace: F3 shows conditional constraints are excluded because they do not appear
in `total_unique_constraints`. PO5 requires this exclusion based on the issue's
"total UniqueConstraints" wording and Django's metadata API.

D4. Keep the existing error and warning bodies unchanged.

Trace: F2 confirms the existing default-backend `auth.E003` and custom-backend
`auth.W004` behavior remains intact when no accepted uniqueness guarantee
exists. PO2 and PO4 require those unchanged outcomes.

D5. Make no compatibility edits.

Trace: F5 found no public API, signature, return-shape, or message compatibility
regression. PO7 requires framing unrelated `check_user_model()` behavior.

D6. Do not claim executed verification.

Trace: F6 records that this benchmark forbids tests, Python execution, and K
tooling. PO8 requires all proof statements to remain "constructed, not
machine-checked"; `fvk/PROOF.md` records the commands but does not report
results from them.

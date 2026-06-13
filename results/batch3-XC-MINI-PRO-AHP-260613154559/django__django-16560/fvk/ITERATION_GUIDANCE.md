# ITERATION_GUIDANCE.md — django__django-16560

Feedback package for the next generate→formalize→verify pass. Each item: the
evidence, an UltimatePowers-style intent question, and the recommended action.

## Verdict

**V1 stands, with one micro-refactor applied (see CHANGE-1).** Every proof
obligation in `PROOF_OBLIGATIONS.md` is discharged (constructed) and no finding in
`FINDINGS.md` is a bug. The audit confirmed the load-bearing property — the
`deconstruct`↔`__eq__` round-trip for a custom code (PO5/PO6, F3) — which is the
single most likely place this kind of change goes wrong.

## Guidance items

### G1 — Confirm the field-only `UniqueConstraint` exclusion is intended (F5/PO10)
- Evidence: `(VALIDATE-CODE)` is non-universal — it excludes
  `UniqueConstraint(fields=..., condition=None)`, which keeps the legacy `"unique"`
  code regardless of `violation_error_code`.
- Classification: underspecified intent (resolved by precedent + docs).
- **UltimatePowers question:** "For a `UniqueConstraint` defined with `fields` and no
  `condition`, should a custom `violation_error_code` override the historical
  `"unique"`/`"unique_together"` code, or (as today) be ignored for backward
  compatibility?"
- Recommended action: **keep V1's behavior** (ignore — consistent with the
  long-documented `violation_error_message` exclusion). Changing it would break the
  legacy field-unique tests and require a behavior change in
  `Model.unique_error_message`. Documented in `docs/ref/models/constraints.txt`.

### G2 — Lock the round-trip with explicit tests (PV2)
- Evidence: `(ROUNDTRIP-CODE)` closes only because emit key = consume key = `__eq__`
  attribute (all `violation_error_code`).
- Classification: test gap.
- Recommended tests (the hidden suite may already include these; the source fix must
  satisfy them): for `CheckConstraint`, `UniqueConstraint`, and postgres
  `ExclusionConstraint` — (a) `deconstruct()` includes `violation_error_code` when
  set and omits it when `None`; (b) `c.clone() == c` and `c != <same w/o code>`;
  (c) `validate()` raises with `code == violation_error_code`; (d) `repr` shows the
  code when set and is unchanged when unset.

### G3 — Document the migration-serializable assumption (F6)
- Evidence: `deconstruct()` places `violation_error_code` into migration `kwargs`.
- Classification: assumption (documentation).
- Recommended action: none in code — the assumption is identical to
  `violation_error_message`. Already noted in the release note / attribute docs.

### G4 — Exception-semantics boundary is acceptable (PV3)
- Evidence: the mini-X `raiseErr` abstracts Python exception propagation.
- Classification: proof capability gap / `[ESCALATION BOUNDARY]`.
- Recommended action: none. The audited property (code propagation at the raise
  site) is fully captured; end-to-end propagation through `full_clean()` is unchanged
  by the fix and is covered by Django's existing integration tests (keep them).

## Code changes emitted this pass

- **CHANGE-1 (cosmetic, optional):** none of the obligations required a source
  change. After re-reading the three `__repr__`s and the `__eq__`s for the
  `(EQ-CODE)`/PO11/PO12 read-offs, the V1 code already orders the code slot before
  the message slot consistently and renders `""` when unset. **No edit was necessary;
  V1 is left unchanged.** (This file records that the "confirm" branch of the task
  was taken, justified by the discharged obligations above.)

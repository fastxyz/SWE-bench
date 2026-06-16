# FVK Notes

Status: constructed, not machine-checked. I did not run tests, Python, or K
tooling.

## Decisions

D-001: Keep V1's parsed-version comparison.

- Trace: F-001, PO-001, PO-002, PO-007.
- Reason: the issue's required behavior is that `0.10.0` satisfies a `0.6.0`
  minimum. V1 compares valid documented version strings with
  `packaging.version.Version`, so it discharges the reported witness and the
  general valid-version obligation.
- Code action: no source edit.

D-002: Keep V1's `InvalidVersion` fallback.

- Trace: F-002, PO-003.
- Reason: public intent is clear for documented version strings, but
  non-PEP-440 strings are underspecified. The fallback preserves the previous
  non-version behavior and avoids a new failure path for existing sentinel or
  custom values. The artifacts explicitly prevent using that fallback as a
  semantic-version proof.
- Code action: no source edit.

D-003: Keep the existing missing-extension and `unknown version` branches.

- Trace: F-003, PO-004, PO-005, PO-008.
- Reason: the original repair request was targeted to the version-ordering
  defect. V1 leaves these existing branches and public signatures unchanged.
- Code action: no source edit.

D-004: Do not broaden the patch to other Sphinx version checks.

- Trace: F-001, PO-001, PO-007, and `fvk/ITERATION_GUIDANCE.md`.
- Reason: the proven and reported observable is `needs_extensions`; the FVK
  proof obligations cover the V1 patch in `repo/sphinx/extension.py`. Other
  Sphinx version checks should be audited under a separate task if broader
  behavior is requested.
- Code action: no source edit.

D-005: Do not modify or delete tests.

- Trace: F-004, PO-009.
- Reason: the user prohibited test edits and execution. The proof is
  constructed only, so no test removal is justified by this FVK pass.
- Code action: no test edit.

## Artifacts Produced

Required artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

Supporting FVK artifacts:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-sphinx-version.k`
- `fvk/needs-extensions-spec.k`

## Final Fix Status

V1 stands unchanged. The FVK audit confirms it satisfies the documented
version-string intent for `needs_extensions` and the concrete issue witness,
while preserving compatibility outside the documented proof domain.

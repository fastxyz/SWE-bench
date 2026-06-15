# FVK Notes

## Decisions

1. Kept the V1 source regex unchanged.

   Reason: Findings F1 and F2 show that the V1 `userinfo_re` fixes the reported
   raw-delimiter and query-smuggling bug family. Proof obligations PO1, PO2,
   PO3, and PO4 are discharged by the constructed K claims and direct regex
   inspection.

2. Kept `?` and `#` excluded from `userinfo_re`.

   Reason: Finding F2 and PO4 trace this to the issue's query-string smuggling
   example. Even though the RFC quote names `:`, `@`, and `/`, allowing `?` or
   `#` would preserve the same authority-smuggling failure mode.

3. Did not loosen the regex to preserve the visible raw-extra-colon fixture.

   Reason: Finding F3 classifies that fixture as SUSPECT legacy evidence because
   it conflicts with the prompt's requirement that raw `:` inside username or
   password data must be encoded. PO3 requires rejecting extra raw colons while
   preserving the single username/password separator.

4. Made no changes to public API surfaces or downstream callers.

   Reason: Finding F4, PO5, and PO8 show ordinary userinfo compatibility and
   public call compatibility are preserved. `PUBLIC_COMPATIBILITY_AUDIT.md`
   found no signature, return-shape, or virtual-dispatch issue.

5. Added no extra source guard around the IDNA fallback.

   Reason: Finding F6 and PO7 show the fallback reruns the same regex and does
   not transform raw forbidden delimiters into valid credential data.

6. Did not run tests, Python, or K tooling.

   Reason: the task forbids execution. Finding F7 and PO9 mark the proof as
   constructed, not machine-checked, and `PROOF.md` records the commands that a
   later machine-checking pass would run.

## Files created

FVK artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`
- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-urlvalidator.k`
- `fvk/urlvalidator-spec.k`

No production source files were changed during the FVK pass.

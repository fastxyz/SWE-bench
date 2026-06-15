# FVK Notes

The FVK audit confirms V1 and does not justify further source edits.

## Decisions

1. Kept `repo/django/db/models/expressions.py` unchanged after V1.

   - Traced to `fvk/FINDINGS.md` F1 and `fvk/PROOF_OBLIGATIONS.md` PO1/PO2.
   - Reason: V1 makes same-type temporal subtraction resolve to
     `DurationField`, which removes the reported
     `DateTimeField + DurationField` mixed-type path in the issue expression.

2. Did not move the fix from output-field inference into SQL rendering.

   - Traced to F2 and PO3.
   - Reason: SQL rendering already uses `TemporalSubtraction` for same-type
     temporal subtraction and already declares duration output. The defect was
     that output-field inference lagged behind that existing SQL path.

3. Did not broaden the fix to all duration arithmetic combinations.

   - Traced to F3 and PO4.
   - Reason: the public issue is temporal subtraction. Direct mixed arithmetic
     such as `DateTimeField + DurationField` remains governed by the existing
     generic inference unless another public requirement asks to change it.

4. Did not modify tests or run verification tooling.

   - Traced to F4, PO5, and PO6.
   - Reason: the benchmark forbids test edits and code/tool execution. The K
     artifacts include exact future commands, labeled constructed and not
     machine-checked.

## Artifact Summary

- `fvk/SPEC.md` states the audited contract and public intent ledger.
- `fvk/FINDINGS.md` records the pre-V1 bug, frame conditions, and residual
  caveat.
- `fvk/PROOF_OBLIGATIONS.md` lists the obligations used to confirm V1.
- `fvk/PROOF.md` gives the constructed proof and future K commands.
- `fvk/ITERATION_GUIDANCE.md` explains why V1 stands.
- Additional FVK adequacy and K files were written because the FVK docs require
  a formal core, not Markdown-only review.

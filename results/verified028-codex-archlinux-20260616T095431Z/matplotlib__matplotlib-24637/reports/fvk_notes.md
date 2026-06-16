# FVK Notes

No additional production-code changes were made in the FVK pass. V1 stands
unchanged because the proof obligations in `fvk/PROOF_OBLIGATIONS.md` are
discharged by the existing V1 edit.

## Decisions

- Kept `renderer.open_group('annotationbbox', gid=self.get_gid())` and
  `renderer.close_group('annotationbbox')` in `AnnotationBbox.draw`. This is the
  direct fix for F-001 and discharges PO-1, PO-2, and PO-7.
- Kept the group opening after the existing visibility and `_check_xy` guard.
  This preserves skipped-annotation behavior and discharges PO-3.
- Kept the existing child draw sequence unchanged. The V1 edit only wraps the
  sequence, which discharges PO-4.
- Did not propagate the parent gid to child artists. F-001 localizes the missing
  observable to the parent renderer group, and PO-6 rejects duplicated child
  ids as the wrong shape for the public hint.
- Did not edit `backend_svg.py` or renderer base classes. PO-5 shows the existing
  renderer API already provides the needed hook, and E5 shows SVG already maps a
  supplied gid to a group id.
- Did not add `try/finally` around child drawing. F-003 records exception-path
  balance as outside this normal-return proof and outside the issue's successful
  SVG-save intent.
- Did not modify tests. F-004 records the missing public coverage, but the task
  forbids test-file edits.

## Artifacts written

The required files are `fvk/SPEC.md`, `fvk/FINDINGS.md`,
`fvk/PROOF_OBLIGATIONS.md`, `fvk/PROOF.md`, and
`fvk/ITERATION_GUIDANCE.md`.

To satisfy the FVK documentation's formal-core and adequacy requirements, this
pass also wrote `fvk/INTENT_SPEC.md`, `fvk/PUBLIC_EVIDENCE_LEDGER.md`,
`fvk/FORMAL_SPEC_ENGLISH.md`, `fvk/SPEC_AUDIT.md`,
`fvk/PUBLIC_COMPATIBILITY_AUDIT.md`, `fvk/mini-python.k`, and
`fvk/annotationbbox-spec.k`.

The K commands are listed in `fvk/PROOF.md` but were not run.

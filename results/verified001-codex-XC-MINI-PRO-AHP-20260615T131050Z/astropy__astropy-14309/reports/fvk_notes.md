# FVK Notes

## Decision

V1 stands unchanged. The FVK audit found no source-code problem beyond the
defect V1 already fixed.

## Trace to Findings and Obligations

- Kept `repo/astropy/io/fits/connect.py` unchanged after V1 because F-001 is
  discharged by PO-003. The reported input reaches the final return with empty
  `args`; V1 evaluates `len(args) > 0` first, so the result is `False` and
  `args[0]` is never read.
- Preserved the existing file-object, suffix, and HDU-object behavior because
  F-002 maps to PO-001, PO-002, and PO-004. V1 edits only the object-fallback
  guard and does not alter those positive identification branches.
- Did not change `identify_format` or any public call protocol because F-003
  maps to PO-005. The registry already passes `*args`; the identifier needed to
  be robust to the empty sequence supplied in the issue reproducer.
- Did not broaden the patch to sibling identifiers because F-004 maps to
  PO-006. Similar `args[0]` patterns exist, but the public stack trace and issue
  text localize this repair to the FITS identifier path for a non-FITS filepath.
- Did not run tests, Python, or K tooling because F-005 maps to PO-007 and the
  benchmark forbids execution. The proof is therefore labeled constructed, not
  machine-checked, and no test removal is recommended.

## Artifacts

The requested FVK artifacts are:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

The FVK method also requires the formal and adequacy core, so this pass emits:

- `fvk/mini-fits-identifier.k`
- `fvk/fits-identifier-spec.k`
- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`

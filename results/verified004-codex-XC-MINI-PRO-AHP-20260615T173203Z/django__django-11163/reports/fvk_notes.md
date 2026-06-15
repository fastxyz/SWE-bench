# FVK Notes

## Decision

V2 keeps the V1 production source unchanged. The FVK audit did not surface a
remaining code defect in `model_to_dict()`.

## Trace from findings and proof obligations

- `F-001` is discharged by `PO-FIELDS-DISTINCTION` and `PO-EMPTY-FIELDS`.
  The V1 condition distinguishes `fields=None` from `fields=[]`, so an empty
  provided list returns `{}`.
- `F-002` is discharged by `PO-FILTER-BEFORE-READ`. The value-read line remains
  after the inclusion and exclusion filters, so `fields=[]` skips every value
  read.
- `F-003` explains why I did not edit adjacent truthiness checks such as
  `_save_m2m()`. `PO-CALLSITE-COMPATIBILITY` limits this repair to the changed
  `model_to_dict()` behavior and confirms no signature or caller-shape change is
  needed.
- `F-004` is handled by `PO-MACHINE-CHECK`. The exact `kompile`, `kast`, and
  `kprove` commands are recorded, but no K tooling was executed.
- `F-005` summarizes the no-change conclusion: `PO-GENERAL-SELECTION`,
  `PO-EXCLUDE-PRECEDENCE`, and `PO-NON-EDITABLE-SKIP` are all satisfied by the
  current source.

## Files added

- `fvk/SPEC.md`: public intent ledger and contract.
- `fvk/FINDINGS.md`: audit findings and V2 decision status.
- `fvk/PROOF_OBLIGATIONS.md`: named proof obligations.
- `fvk/PROOF.md`: constructed proof sketch and run commands.
- `fvk/ITERATION_GUIDANCE.md`: next-step guidance and no-change decision.
- `fvk/mini-python.k` and `fvk/model-to-dict-spec.k`: constructed formal core.
- `fvk/INTENT_SPEC.md`, `fvk/PUBLIC_EVIDENCE_LEDGER.md`,
  `fvk/FORMAL_SPEC_ENGLISH.md`, `fvk/SPEC_AUDIT.md`, and
  `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`: adequacy and compatibility artifacts
  required by the FVK method.

## Source edits

No source file under `repo/` was changed during the FVK pass. The V1 edit in
`repo/django/forms/models.py` stands as the final production fix.

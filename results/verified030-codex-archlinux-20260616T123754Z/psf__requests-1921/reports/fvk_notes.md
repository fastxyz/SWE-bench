# FVK Notes

The FVK audit confirmed V1 and did not justify a V2 source edit.

## Decisions

- Kept `repo/requests/sessions.py` unchanged. Finding FVK-F1 identifies the
  original bug as a final merged header value of `None` surviving into the
  prepared headers; PO-1 and PO-3 require deleting final `None` values. V1 does
  exactly that by computing `none_keys` from `merged_setting.items()`.
- Kept the merge-level placement. FVK-F1 and PO-3 trace the bug to merge
  semantics before `PreparedRequest.prepare_headers()` consumes the mapping, so
  filtering later would be less direct and would not address the helper
  contract.
- Kept session state unmutated. PO-6 requires deletion on the merged copy only;
  V1 satisfies this because `merged_setting` is created from `dict_class(...)`
  before any keys are deleted.
- Kept request override behavior unchanged. PO-2 and PO-4 require request
  values to win before deletion, so a request-level non-`None` value still
  overrides a session-level `None`.
- Kept the existing early return for `request_setting is None`. FVK-F3 records
  this as an underspecified direct-helper edge, not a public issue-path bug,
  because PO-8 shows ordinary missing request headers are normalized to `{}` and
  therefore enter the mapping/mapping branch.

## Artifacts

- `fvk/SPEC.md` records the target contract and public intent ledger summary.
- `fvk/FINDINGS.md` records the resolved bug, compatibility confirmations, and
  the non-blocking direct-helper ambiguity.
- `fvk/PROOF_OBLIGATIONS.md` maps the issue intent to proof obligations.
- `fvk/PROOF.md` gives the constructed proof and the commands to machine-check
  later.
- `fvk/ITERATION_GUIDANCE.md` explains why V1 stands and what future work would
  be useful outside this benchmark constraint.

No tests, Python, or K tools were run, as required.

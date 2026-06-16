# FVK Notes

Status: constructed, not machine-checked.

## Source decision

No source files were changed during the FVK pass. V1 stands.

The decision is traced to these findings and proof obligations:

- F1 and PO1 show that reverse many-to-one async methods now dispatch to the
  related manager sync methods. V1's local wrappers in
  `repo/django/db/models/fields/related_descriptors.py` are sufficient.
- F2 and PO2 show that many-to-many async methods now dispatch to the m2m sync
  methods and preserve `through_defaults`. V1's m2m wrapper signatures are kept
  because PO2 and PO5 require the async API to mirror the sync related-manager
  API, including `through_defaults`.
- F3 and PO3 justify keeping the V1 changes in
  `repo/django/contrib/contenttypes/fields.py`. Although the public issue hint
  showed `related_descriptors.py`, generic related managers have the same
  copied-queryset async bypass and public sync related-manager behavior.
- F4 and PO4 justify not changing `BaseManager._get_queryset_methods()` or
  `QuerySet`. The issue is local to related managers, and a global manager proxy
  rewrite would exceed the public intent.
- PO6 confirms the `alters_data = True` assignments for all new async wrappers.

## Artifact decisions

The requested five FVK artifacts were written:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

The FVK docs require a formal core and adequacy gate, so I also wrote:

- `fvk/mini-related-manager.k`
- `fvk/related-manager-async-spec.k`
- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`

The K model abstracts the database to relation-specific effects, but it keeps
the defect's observable distinction: local related-manager sync dispatch versus
queryset proxy dispatch. It also keeps `through_defaults` observable for the
many-to-many case.

## Execution constraints

No tests, Python, or K framework tooling were run. The K commands are recorded
in `fvk/PROOF.md` for later machine checking only, as required by the task.

# FVK Notes

## Decision

V1 stands unchanged. The FVK audit did not surface a source defect in the V1
`Model._set_pk_val()` chain walk.

## Trace to findings and proof obligations

`fvk/FINDINGS.md` F1 identifies the legacy bug: the old setter left inherited
parent primary-key values stale, allowing `_save_table()` to update an old
parent row. `fvk/PROOF_OBLIGATIONS.md` PO1 and PO4 define the required fix:
clear every field in the active primary-key parent-link chain so ordinary save
does not update through stale PK values. V1 satisfies those obligations by
assigning the current field and then following `target_field` while
`remote_field.parent_link` is true.

`fvk/FINDINGS.md` F2 is the positive confirmation for V1's behavior on one-level
and multi-level MTI primary-key chains. It is backed by PO1 and PO2, which model
the loop over a finite acyclic parent-link chain.

`fvk/FINDINGS.md` F3 and F5 explain why I did not broaden the patch to all
entries in `_meta.parents`: the public hints say that approach failed for
multiple-model inheritance, and PO3/PO5 require a frame condition that leaves
non-primary parent links untouched. This is also recorded in
`fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.

`fvk/FINDINGS.md` F4 records a residual ambiguity around direct inherited field
assignment, such as `derived.uid = None`. I left V1 unchanged because the public
discussion narrows the reliable API obligation to `derived.pk = None`; supporting
direct field assignment would require a separate descriptor or save-path design
outside the proven `pk` setter contract.

## Artifacts produced

The five requested FVK artifacts are complete:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

I also added the FVK adequacy and formal-core files required by the method:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-django-pk.k`
- `fvk/model-pk-spec.k`

The proof is constructed, not machine-checked. I did not run tests, Python, or
K tooling, per the task constraints.

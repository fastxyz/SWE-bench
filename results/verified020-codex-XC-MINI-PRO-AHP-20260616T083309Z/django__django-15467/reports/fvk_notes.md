# FVK Notes

## Source decision

I kept the V1 source fix unchanged.

This decision is justified by `fvk/FINDINGS.md` F1-F4 and
`fvk/PROOF_OBLIGATIONS.md` PO1-PO6:

- F1 identifies the original bug: a blank radio `ForeignKey` with a custom
  `empty_label` was overwritten by `_("None")`. PO1 requires preserving the
  explicit value, and V1 satisfies it with
  `kwargs.get("empty_label", _("None"))`.
- F2 identifies why the issue's suggested truthiness expression is insufficient:
  `empty_label=None` is documented as meaningful. PO6 rejects the truthiness
  fallback, so V1's key-presence default is the correct behavior to keep.
- F3 and PO3 confirm that nonblank radio fields should still suppress the empty
  choice by using `None`; V1 leaves that behavior intact.
- F4 and PO5 confirm there is no public compatibility break because the method
  signature, override pattern, queryset handling, and final
  `db_field.formfield(**kwargs)` dispatch remain unchanged.

No FVK finding showed a source-level defect remaining in
`repo/django/contrib/admin/options.py`, so no V2 source edit was made.

## Artifact decisions

I wrote the five requested FVK artifacts:

- `fvk/SPEC.md` records the intent spec, public evidence ledger, formal English
  claims, adequacy audit, compatibility audit, and the non-executed K commands.
  Its claims correspond to PO1-PO5 and explain why F1-F4 are discharged.
- `fvk/FINDINGS.md` records the original bug (F1), the avoided truthiness bug
  (F2), the nonblank frame condition (F3), compatibility status (F4), and proof
  honesty status (F5).
- `fvk/PROOF_OBLIGATIONS.md` lists PO1-PO7, including preservation, fallback,
  nonblank behavior, frame reasoning, compatibility, truthiness rejection, and
  no-execution honesty.
- `fvk/PROOF.md` constructs the symbolic case proof for PO1-PO5, rejects the
  weaker alternative from F2/PO6, and explains why the proof supports keeping V1
  unchanged.
- `fvk/ITERATION_GUIDANCE.md` states that V1 stands because F1-F4 and PO1-PO6
  are resolved, lists normal-environment test ideas without running them, and
  records residual risk from F5/PO7.

I also added `fvk/mini-admin-empty-label.k` and
`fvk/admin-radio-empty-label-spec.k` because the FVK documentation says the
formal core should not be Markdown-only. These files model only the audited
decision: resolving the `empty_label` value for admin radio foreign keys. Their
three claims correspond to PO1, PO2, and PO3.

## Execution limits

I did not run tests, Python, `kompile`, `kast`, or `kprove`. The proof is
therefore constructed, not machine-checked, matching F5 and PO7.

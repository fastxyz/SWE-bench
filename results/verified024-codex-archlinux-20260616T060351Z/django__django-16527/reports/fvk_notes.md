# FVK Notes

## Decision Summary

V1 stands unchanged. The FVK audit confirmed that the intended contract for
`show_save_as_new` is:

```text
not is_popup
and has_add_permission
and has_change_permission
and change
and save_as
```

## Decisions and Traceability

* Kept the V1 source edit in
  `repo/django/contrib/admin/templatetags/admin_modify.py`.
  * Trace: `fvk/FINDINGS.md` F1 and `fvk/PROOF_OBLIGATIONS.md` PO-1.
  * Reason: F1 shows the pre-V1 counterexample where a user without add
    permission still saw "Save as new"; PO-1 is discharged by adding
    `has_add_permission` to the conjunction.
* Kept the existing `has_change_permission` and `change` requirements.
  * Trace: `fvk/FINDINGS.md` F2 and `fvk/PROOF_OBLIGATIONS.md` PO-2.
  * Reason: the public hint says "Save as New" is also a save of the current
    object, so checking only add permission would be too weak.
* Did not edit `repo/django/contrib/admin/options.py`.
  * Trace: `fvk/FINDINGS.md` F3 and `fvk/PROOF_OBLIGATIONS.md` PO-7.
  * Reason: the backend `_saveasnew` path already converts the request to an add
    operation and checks `has_add_permission`, so the remaining defect was UI
    visibility.
* Did not edit templates.
  * Trace: `fvk/PROOF_OBLIGATIONS.md` PO-5.
  * Reason: `submit_line.html` already renders the `_saveasnew` input from the
    `show_save_as_new` flag; fixing the flag fixes the rendered control.
* Did not run tests, Python, or K tooling, and did not recommend test removal.
  * Trace: `fvk/FINDINGS.md` F4.
  * Reason: this task forbids execution, and the proof is constructed rather
    than machine-checked.

## Artifacts Written

The required FVK artifacts are:

* `fvk/SPEC.md`
* `fvk/FINDINGS.md`
* `fvk/PROOF_OBLIGATIONS.md`
* `fvk/PROOF.md`
* `fvk/ITERATION_GUIDANCE.md`

The supporting FVK adequacy and formal-core artifacts are:

* `fvk/INTENT_SPEC.md`
* `fvk/PUBLIC_EVIDENCE_LEDGER.md`
* `fvk/FORMAL_SPEC_ENGLISH.md`
* `fvk/SPEC_AUDIT.md`
* `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
* `fvk/mini-submit-row.k`
* `fvk/submit-row-spec.k`

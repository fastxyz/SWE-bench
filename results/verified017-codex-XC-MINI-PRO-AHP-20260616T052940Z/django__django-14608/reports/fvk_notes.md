# FVK Notes

## Decision summary

V1 stands unchanged. The FVK audit found the original issue-level bug and
confirmed that the V1 source change discharges the relevant obligations:
`BaseFormSet.full_clean()` now constructs formset non-form `ErrorList`
instances with `error_class='nonform'` in both construction paths.

## Decisions traced to findings and proof obligations

1. Keep the `repo/django/forms/formsets.py` V1 code.

   Trace: FINDINGS.md F1 identifies the pre-V1 bug: both
   `_non_form_errors` construction sites omitted `nonform`. PO-1 requires the
   initially created list to be tagged, and PO-2 requires the replacement list
   in the `ValidationError` branch to be tagged. V1 satisfies both by passing
   `error_class='nonform'` at both call sites.

2. Keep the documentation update in `repo/docs/topics/forms/formsets.txt`.

   Trace: PO-5 requires developer-facing documentation because the public
   issue explicitly asks to document the class. The V1 docs paragraph and HTML
   example discharge this obligation.

3. Do not revise V1 to preserve old plain `ErrorList` rendering.

   Trace: FINDINGS.md F2 records the public admin test expectation that
   compares against `ErrorList([...])` without `nonform`. PO-6 classifies that
   as suspect legacy evidence because it conflicts with the issue's requested
   behavior. The fix should follow the public issue intent, not the old
   rendering expectation.

4. Do not change `repo/django/forms/models.py` in this pass.

   Trace: FINDINGS.md F4 records the nearby model formset assignments to a
   form's `NON_FIELD_ERRORS`. PO-3 and PO-4 frame the audited behavior as
   formset-level `non_form_errors()` contents and value shape. The model formset
   assignments are per-form non-field errors, not the formset non-form
   observable named by the issue, so no additional source edit is justified.

5. Use the finite path K model instead of a full Python/Django semantics.

   Trace: FINDINGS.md F3 marks full Django validation as a proof capability
   boundary, not a code bug. PO-1 through PO-4 only require preserving error
   contents while proving the extra class on every formset non-form outcome.
   The mini-model preserves that axis and distinguishes the pre-fix no-class
   behavior from V1, so it is adequate for this issue-level audit.

## Verification status

The FVK proof is constructed, not machine-checked. I did not run tests, Python,
`kompile`, `kast`, or `kprove`, per the benchmark instructions. The exact
future K commands are recorded in `fvk/PROOF.md`.

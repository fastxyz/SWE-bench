# FVK Notes

Status: constructed, not machine-checked. Per task constraints, I did not run
tests, Python, `kompile`, `kast`, or `kprove`.

## Decision

V1 stands unchanged. No production source files were edited during the FVK pass.

The decision is justified by `fvk/FINDINGS.md` and
`fvk/PROOF_OBLIGATIONS.md`:

- `F-001` / `PO-1` confirms the issue case is covered: an eligible defaulted
  field omitted from raw data but given a non-empty derived `cleaned_data` value
  no longer skips assignment.
- `F-002` / `PO-2` confirms V1 preserves public behavior for ordinary omitted
  empty values, which should keep model defaults.
- `F-004` / `PO-3` confirms submitted blank values and widgets that report "not
  omitted" still assign cleaned values.
- `PO-4`, `PO-5`, and `PO-6` confirm V1 does not broaden the change to
  non-default fields, file-field ordering, or pre-existing skip filters.
- `F-005` / `PO-7` confirms public API and hook compatibility.
- `F-003` / `PO-8` records the only residual issue: explicit empty-value
  overrides are underspecified. That ambiguity does not justify a source change
  because public tests require preserving defaults for ordinary omitted empty
  values and current `cleaned_data` does not track whether an empty value was
  manually reassigned.

## Artifacts Added

- `fvk/SPEC.md`: human-readable specification, public intent ledger summary,
  decision table, and adequacy verdict.
- `fvk/FINDINGS.md`: findings F-001 through F-005, including the closed V1 bug
  and the residual empty-value ambiguity.
- `fvk/PROOF_OBLIGATIONS.md`: obligations PO-1 through PO-8 mapped to public
  evidence, K claims, and V1 source behavior.
- `fvk/PROOF.md`: constructed proof sketch and the exact K commands that should
  be run later in a K-enabled environment.
- `fvk/ITERATION_GUIDANCE.md`: conclusion that V1 stands, plus future test and
  clarification guidance.
- `fvk/mini-model-form.k` and `fvk/construct-instance-spec.k`: formal core for
  the abstract field-decision model and reachability claims.
- `fvk/INTENT_SPEC.md`, `fvk/PUBLIC_EVIDENCE_LEDGER.md`,
  `fvk/FORMAL_SPEC_ENGLISH.md`, `fvk/SPEC_AUDIT.md`, and
  `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`: adequacy and compatibility artifacts
  required by the FVK methodology.

## Source Decision Trace

The audited source is `repo/django/forms/models.py:51-55`. V1's predicate skips
only when all three facts hold: the model field has a default, the widget says
the value was omitted, and the cleaned value is one of the form field's empty
values. That is exactly the conjunction in `PO-2`; negating any member of the
conjunction reaches assignment or file queueing under `PO-1`, `PO-3`, `PO-4`,
and `PO-5`.

No additional code edit was made because the proof obligations that trace to
public intent are discharged, and the only unresolved case is explicitly marked
underspecified rather than a confirmed defect.

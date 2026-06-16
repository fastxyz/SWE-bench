# FVK Notes

## Decision

V1 stands unchanged. I did not edit production source during the FVK pass.

This decision is based on:

- `fvk/FINDINGS.md` F1 and `fvk/PROOF_OBLIGATIONS.md` PO4/PO10: disabled
  callable initials now flow through `bf.initial`, addressing the issue's
  `DateTimeField` example.
- F2 and PO5: `FileField` cleaning now receives `bf.initial`, removing another
  direct initial lookup path.
- F3 and PO7/PO8/PO9: `changed_data` now aggregates `BoundField._has_changed()`
  decisions while preserving both non-hidden and hidden-initial behavior.
- F4 and PO8: the hidden-initial `ValidationError` behavior remains unchanged.
- F5 and PO11: the only compatibility concern is the new private
  `BoundField._has_changed()` expectation for custom bound-field objects. No
  in-repo override returns an incompatible object, and adding a fallback in
  `BaseForm.changed_data` would reintroduce the duplicate path the issue asks
  Django to remove.

## Artifacts Added

- `fvk/SPEC.md`: records the public intent ledger and the formalized behavior
  for `_bound_items()`, `_clean_fields()`, `changed_data`, and
  `BoundField._has_changed()`.
- `fvk/FINDINGS.md`: records the audit findings F1-F6 and classifies V1 as
  satisfying the issue intent.
- `fvk/PROOF_OBLIGATIONS.md`: records PO1-PO11, including the disabled initial,
  `FileField`, hidden-initial, aggregation, and compatibility obligations.
- `fvk/PROOF.md`: gives the constructed proof over those obligations and records
  the K commands that were not executed.
- `fvk/ITERATION_GUIDANCE.md`: records that V1 stands and lists future checks if
  execution or K tooling is available.
- `fvk/mini-django-forms.k` and `fvk/django-forms-spec.k`: provide a small
  constructed K-shaped semantics and claim skeleton for the proof artifacts.

## Execution Limits

Per the benchmark instructions, I did not run tests, Python, `kompile`, `kast`,
or `kprove`. The proof is therefore constructed and source-audited, not
machine-checked.

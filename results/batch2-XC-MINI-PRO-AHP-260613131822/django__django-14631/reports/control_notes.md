# Control notes — django__django-14631 (post-review)

This documents the review outcome and every decision, each traced to a numbered
entry in `review/FINDINGS.md`. `reports/baseline_notes.md` remains the V1 record;
where it differs from the current code (the method name), this file supersedes it.

## Summary of the review

V1 was found correct against the ticket and faithful to the reference design in
`PROBLEM.md`. One concrete change was made (a private-method rename); every other
path was verified equivalent to the pre-fix code or an intended behaviour change.
The fix still consists of: `BaseForm._bound_items()`, a `BoundField` per-field
change-detection helper, and `_clean_fields`/`changed_data` rewritten to read their
values through the `BoundField`.

## Decisions

### 1. Keep the core `_clean_fields` change (disabled → `bf.initial`)
Kept unchanged. **Finding 1** establishes this is the actual root-cause fix: it
routes the disabled-field value through the cached, microsecond-normalised
`BoundField.initial`, so `cleaned_data[name]` equals `form[name].initial`.
**Finding 3** confirms the non-disabled and `FileField` paths remain equivalent to
the pre-fix code, so nothing else in `_clean_fields` changed behaviour.

### 2. Keep the `changed_data` one-liner + `_did_change` extraction
Kept unchanged in structure. **Finding 2** proves the extracted per-field logic is
line-for-line equivalent to the old inline loop (data via `bf.data`, initial via
`bf.initial` or the `show_hidden_initial` branch, `ValidationError` ⇒ treat as
changed), and that `changed_data` still returns `list[str]`.

### 3. Rename `_has_changed` → `_did_change`  *(the one code change)*
Changed in `django/forms/boundfield.py` (definition) and `django/forms/forms.py`
(the single call site in `changed_data`). Justified by **Finding 4**: V1 had copied
`_bound_items()` verbatim from the hint but renamed the other helper to
`_has_changed`, an internal inconsistency and a deviation from the only allowed
naming signal. **Finding 4** also records the grep evidence that no test references
either name, so the rename is behaviourally invisible (cross-checked against
**Finding 6**). Aligning both helpers with the hint keeps the change resting solely
on allowed inputs.

### 4. Do **not** try to preserve old microsecond behaviour for disabled datetimes
Deliberately left as the new (stripped/cached) behaviour. **Finding 5**: this is the
ticket's intended outcome; the repo test at test_forms.py:2123 that asserts the old
behaviour is the one `PROBLEM.md` says to adjust, and the fix is logically
incompatible with that old assertion. Reverting it would re-introduce the bug.

### 5. Do not touch surrounding/disabled-field code paths
No edits to `value()`, `Field.has_changed`, the auth/admin consumers, or model
forms. **Finding 6** verifies the adjacent disabled-field tests still pass;
**Finding 7** verifies the public contracts (`changed_data` shape, retained helper
methods) are intact; **Finding 8** verifies no subclass overrides the refactored
methods and that field-level `has_changed` overrides are still dispatched by
`_did_change`.

### 6. Keep the `ValidationError` import and helper placement
Kept. **Finding 9** confirms the import is required by the `show_hidden_initial`
branch and that error/exception semantics match the pre-fix code. **Finding 10**
confirms the caching/iteration semantics (`_bound_items` reusing
`_bound_fields_cache`, the `cached_property` `initial`) are exactly what makes the
fix consistent, and that `full_clean` ordering is safe.

## Net change relative to V1

Only the `_has_changed` → `_did_change` rename. No behavioural change relative to
V1; the rename is purely for naming fidelity/consistency with the hint and is
test-invisible (Finding 4).

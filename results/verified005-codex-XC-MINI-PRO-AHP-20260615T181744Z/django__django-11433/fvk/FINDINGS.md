# FVK Findings

Status: constructed, not machine-checked. Findings are derived from public
intent, source inspection, and the constructed proof obligations. No tests,
Python, `kompile`, or `kprove` were run.

## F-001: Pre-V1 skipped non-empty derived cleaned values

Classification: code bug fixed by V1.

Input class: eligible non-file model field with `hasDefault=true`,
`omittedFromData=true`, and `cleanedEmpty=false`.

Observed before V1: the old predicate skipped every defaulted omitted field,
therefore `cleaned_data[f.name]` could not overwrite the model default.

Expected: assign the non-empty derived cleaned value.

Evidence: prompt E1/E2; obligation PO-1; claim
`CI-DERIVED-NONEMPTY-ASSIGNS`.

V1 status: closed. The skip now also requires
`cleaned_data.get(f.name) in form_field.empty_values`, so non-empty derived
values reach `save_form_data()`.

## F-002: Ordinary omitted empty values must continue preserving defaults

Classification: compatibility/frame condition confirmed.

Input class: eligible model field with `hasDefault=true`,
`omittedFromData=true`, and `cleanedEmpty=true`.

Observed in public tests: empty omitted data for optional text, split datetime,
file, and select-date fields keeps the model default.

Expected: skip assignment.

Evidence: E4; obligation PO-2; claim
`CI-OMITTED-EMPTY-PRESERVES-DEFAULT`.

V1 status: closed. V1 preserves this behavior.

## F-003: Explicit empty-value cleaned-data overrides remain underspecified

Classification: underspecified intent / test gap, not a V1 code bug.

Input class: an eligible defaulted field omitted from raw data where custom
`clean()` deliberately sets `cleaned_data[f.name]` to an empty value such as
`''` or `None`.

Observed with V1 by reasoning: the value is in `form_field.empty_values`, so the
field is skipped and the model default remains.

Possible expected result: if the issue text is interpreted as "any
`cleaned_data` value, including empty values, always overwrites defaults," this
case would assign the empty value.

Why not changed: public tests require normal omitted values that clean to empty
to preserve defaults, and `cleaned_data` does not record whether an empty value
was manually reassigned or merely produced by ordinary field cleaning. Changing
this would require a broader provenance-tracking design not justified by the
public issue.

Evidence: ambiguity A1; obligations PO-2 and PO-8.

V1 status: accepted with residual ambiguity documented.

## F-004: Widget omission semantics remain compatible

Classification: compatibility/frame condition confirmed.

Input class: defaulted field whose widget returns `omittedFromData=false`, such
as checkbox or multiple-select widgets.

Observed/expected: default preservation must not apply; the cleaned value is
assigned or queued.

Evidence: E5/E6; obligation PO-3; claim `CI-SUBMITTED-EMPTY-ASSIGNS`.

V1 status: closed. The new empty-value check is nested under the existing widget
omission check, so widgets that return false remain unaffected.

## F-005: Public API and hook compatibility preserved

Classification: compatibility confirmed.

Input class: public callers and widget/model field hooks.

Observed/expected: no signature changes; no new hook arguments; existing
`value_omitted_from_data()` and `save_form_data()` contracts remain unchanged.

Evidence: `PUBLIC_COMPATIBILITY_AUDIT.md`; obligation PO-7.

V1 status: closed.

## Proof-Derived Findings from `/verify`

The constructed proof does not surface a source-code defect beyond F-003's
underspecified empty-value provenance. All decision-table claims needed for the
public issue and existing public frame conditions reduce to a single branch
selection in `mini-model-form.k`.

Machine-check caveat: the proof was constructed only. The commands in
`PROOF.md` must be run in an environment with K before treating any test as
formally redundant.

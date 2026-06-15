# FVK Specification for django__django-11433

Status: constructed, not machine-checked. No tests, Python, `kompile`, or
`kprove` were run.

## Audited Unit

`repo/django/forms/models.py:31-65`, specifically the per-field decision in
`construct_instance()`:

1. skip ineligible fields;
2. preserve defaults for omitted defaulted fields only when the cleaned value is
   empty;
3. otherwise assign `cleaned_data[f.name]`, either immediately for normal fields
   or through the existing file-field queue.

The whole Django form/model object graph is abstracted to a single field
decision in `mini-model-form.k`. This abstraction is property-complete for the
bug because it preserves the axes the issue manipulates: `has_default`,
`value_omitted_from_data`, cleaned-value emptiness, and file-vs-non-file
assignment shape.

## Intent Ledger

See `PUBLIC_EVIDENCE_LEDGER.md` for the full table. Critical entries:

- E1/E2: the prompt requires `cleaned_data` to overwrite model defaults when a
  field is omitted from submitted data because the value is derived during
  cleaning.
- E4: public tests require ordinary omitted optional fields that clean to empty
  values to keep the model default.
- E5/E6: public tests and widget implementations require submitted blank values,
  checkboxes, and multiple-select widgets to bypass the default-preservation
  skip when `value_omitted_from_data()` is false.
- E8: file fields must retain the existing delayed assignment path.
- E10: explicit empty-value overrides are underspecified by public evidence.

## Formal Domain

A field is in the assignment domain when:

- `editable == true`;
- `isAuto == false`;
- `inCleaned == true`;
- `fieldsAllowed == true`;
- `excluded == false`.

The default-preservation decision is considered only inside that domain.

## Intended Decision Table

| In-domain conditions | Expected action |
| --- | --- |
| `hasDefault && omittedFromData && cleanedEmpty` | `skip` so the model default remains |
| `hasDefault && omittedFromData && !cleanedEmpty && !isFile` | `assign(name, cleanedValue)` |
| `hasDefault && omittedFromData && !cleanedEmpty && isFile` | `queueFile(name, cleanedValue)` |
| `hasDefault && !omittedFromData && !isFile` | `assign(name, cleanedValue)`, even when empty |
| `!hasDefault && !isFile` | `assign(name, cleanedValue)` |
| Ineligible field | `skip` |

## Formal Artifacts

- `mini-model-form.k`: abstract K semantics for the field decision.
- `construct-instance-spec.k`: K reachability claims for the decision table.
- `INTENT_SPEC.md`, `FORMAL_SPEC_ENGLISH.md`, `SPEC_AUDIT.md`, and
  `PUBLIC_COMPATIBILITY_AUDIT.md`: adequacy and compatibility gate.

## Adequacy Verdict

The formal claims match the public intent for the non-empty derived cleaned-data
case and the public frame conditions for existing default behavior. The only
ambiguous point is whether an explicitly reassigned empty cleaned value should
override a default when the field was omitted. V1 intentionally does not change
that behavior because public tests require ordinary omitted empty values to
preserve defaults, and no public evidence distinguishes those from explicit
empty reassignment.

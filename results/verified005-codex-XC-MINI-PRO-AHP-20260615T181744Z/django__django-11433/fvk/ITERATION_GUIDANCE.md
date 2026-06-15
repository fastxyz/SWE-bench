# Iteration Guidance

## Decision

V1 stands unchanged.

Rationale: PO-1 through PO-7 are discharged by the V1 source and match the
public intent ledger. The only unresolved point is F-003 / PO-8, explicit empty
cleaned-value override provenance. That ambiguity is not enough to justify a
broader source change because public tests require ordinary omitted empty values
to preserve defaults.

## No Source Edits Applied in the FVK Pass

The FVK audit did not identify a source-code defect in V1 for the public issue.
No production source files were changed after the V1 patch.

## Recommended Future Tests

Do not edit tests in this benchmark, but a normal Django change should add a
regression test for PO-1:

1. Define a ModelForm for a model field with a default.
2. Omit the field from submitted data.
3. In `clean()`, derive a non-empty value for that field and place it in
   `cleaned_data`.
4. Assert that `save(commit=False)` assigns the derived value, not the model
   default.

Future design work could clarify F-003: whether explicitly assigning an empty
value in `cleaned_data` should override a default when the raw payload omitted
the field. Supporting that would likely require provenance tracking for
cleaned-data mutations, not just changing the skip predicate.

## Commands for Later Machine Check

These commands are recorded but were not executed:

```sh
kompile fvk/mini-model-form.k --backend haskell
kast --backend haskell fvk/construct-instance-spec.k
kprove fvk/construct-instance-spec.k
```

# FVK Spec

Status: constructed for FVK audit, not machine-checked.

## Target

The target is the return-type augmentation behavior of
`repo/sphinx/ext/autodoc/typehints.py`, specifically
`augment_descriptions_with_types(node, annotations)`.

The formal model abstracts docutils nodes into a sequence of field-name tokens:
`paramField(name)`, `paramTypedField(name)`, `typeField(name)`,
`returnField`, `returnsField`, `rtypeField`, and `otherField(name)`. This
abstraction preserves the property under verification because the bug is exactly
which first field-name token is recognized as a documented return description.
It distinguishes the failing pre-fix case (`returnsField` without `rtypeField`)
from the passing post-fix case.

## Public Intent Ledger Summary

The detailed ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. The core obligations
are:

- `return` and `returns` are equivalent Python-domain return-description field
  names.
- Napoleon emits `returns`, so autodoc must recognize it before doc-field
  transformation.
- In `"documented"` mode, a return annotation is emitted as `rtype` only when the
  return value is documented and no `rtype` is already present.
- Parameter behavior, public APIs, config names, and Napoleon output format are
  frame conditions.

## Formal Contract

Let:

- `hasReturnDescription(fields)` be true iff `fields` contains `returnField` or
  `returnsField`.
- `hasReturnType(fields)` be true iff `fields` contains `rtypeField`.
- `hasReturnAnnotation` be true iff `annotations` contains key `"return"`.
- `annotation` be the recorded return annotation string.

The return-type augmentation contract is:

1. If `hasReturnAnnotation` is true, `hasReturnDescription(fields)` is true, and
   `hasReturnType(fields)` is false, the function appends one `rtype` field
   containing `annotation`.
2. If no return annotation exists, no `rtype` field is appended by return-type
   augmentation.
3. If no return description exists, no `rtype` field is appended in
   documented-description mode.
4. If an `rtype` field already exists, no duplicate `rtype` field is appended.
5. Existing parameter-description/type behavior is unchanged by the return alias
   fix.

## Invariants

For the scan loop over field-list entries:

- After scanning any prefix, `has_description` contains canonical key `"return"`
  iff the prefix contains `return` or `returns`.
- After scanning any prefix, `has_type` contains canonical key `"return"` iff the
  prefix contains `rtype`.
- Parameter description/type sets are affected only by `param` and `type` field
  names, not by `return`, `returns`, or `rtype`.

For the append phase:

- A return `rtype` field is appended iff `"return"` is in annotations,
  canonical return description is present, and canonical return type is absent.

## Scope Notes

The `"all"` target branch is a frame condition rather than the primary contract:
it already adds missing `rtype` based on annotations and existing `rtype`, not
based on whether a return description was documented. The reported defect is the
`"documented"` branch.

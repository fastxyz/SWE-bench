# Public Compatibility Audit

## Changed Symbols

No public function, class, method, or directive signature changed.

## Behavioral Surface

- `DocFieldTransformer.transform()` now interprets inline typed field arguments
  by the final token as the parameter name.
- `modify_field_list()` and `augment_descriptions_with_types()` now classify
  inline typed `:param type name:` fields by final token as the parameter name.

## Public Callsites and Overrides

Search scope reviewed:

- `TypedField` use in Python, Napoleon's patched Python fields, JavaScript, and
  C domains.
- Internal calls to `modify_field_list()` and
  `augment_descriptions_with_types()`.

Findings:

- No caller signature or return-shape update is required.
- Existing public one-word inline examples remain covered by the new rule.
- The common `TypedField` behavior change is intentional for the generic
  `:param type name:` convention.  Public ambiguous domain-specific declarator
  cases were not found in the repository evidence and are outside this issue's
  intent.

Status: compatible.

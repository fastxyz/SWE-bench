# SPEC

Status: constructed, not machine-checked.

## Scope

This FVK audit covers the V1 change in
`repo/sphinx/ext/autodoc/typehints.py`, specifically the data path:

1. `record_typehints()` records annotations during `autodoc-process-signature`.
2. `merge_typehints()` runs only for Python objects when `autodoc_typehints` is
   `description`.
3. `modify_field_list()` inserts recorded annotation strings into `type NAME` and
   `rtype` fields.

The disputed observable is the rendered annotation string in description-mode
parameter and return type fields.

## Public intent ledger

Critical public evidence is mirrored in `PUBLIC_EVIDENCE_LEDGER.md`; the controlling
entries are:

* E1-E3: the issue requires `types.JSONObject` instead of expanded `Dict[str, Any]`
  when `autodoc_typehints = 'description'`.
* E4-E5: docs define `description` as field-content rendering and aliases as a way
  to keep aliases unevaluated in documents.
* E6-E7: the existing signature path already uses
  `inspect.signature(..., type_aliases=...)` and public tests rely on alias-aware
  signature output.
* E8-E9: V1 routes description-mode recording through the same resolver and leaves
  merge shape unchanged.

## Contract

For any callable in the audited domain:

* Precondition P1: the callable is processed by `record_typehints()`.
* Precondition P2: raw annotations are available to
  `sphinx.util.inspect.signature()`.
* Precondition P3: `app.config.autodoc_type_aliases` is the configured alias map.
* Postcondition Q1: each recorded parameter annotation string is
  `typing.stringify()` of the alias-aware signature annotation.
* Postcondition Q2: the recorded return annotation string is
  `typing.stringify()` of the alias-aware signature return annotation.
* Postcondition Q3: in description mode, generated `type NAME` and `rtype` fields
  use the recorded strings unchanged unless the user already supplied equivalent
  fields.

For the issue instance:

* Raw parameter annotation: `JSONObject`.
* Raw return annotation: `JSONObject`.
* Alias map: `JSONObject -> types.JSONObject`.
* Required recorded parameter string: `types.JSONObject`.
* Required recorded return string: `types.JSONObject`.
* Rejected legacy string: `Dict[str, Any]`.

## Frame conditions

* No public callback signature changes.
* No test files are modified.
* Existing duplicate-prevention behavior in `modify_field_list()` is preserved.
* Behavior without a matching alias continues to use existing signature/stringify
  behavior.

## Formal artifacts

* `mini-python-autodoc.k` defines the abstract transition system for the disputed
  property.
* `autodoc-typehints-spec.k` states the claims used by `PROOF.md`.

# FVK Findings

Status: constructed, not machine-checked. No tests or project code were run.

## F-001: Resolved empty-fields bug

- Classification: code bug, resolved by V1.
- Evidence: E-001, E-002, PO-EMPTY-FIELDS, PO-FIELDS-DISTINCTION.
- Input: `model_to_dict(instance, fields=[])` for any instance whose model has at
  least one editable field.
- Pre-V1 observed behavior: the truthiness check treated `[]` like `None`, so
  all editable fields were returned.
- Expected behavior: `{}`, because the provided inclusion list contains no field
  names.
- V1/V2 status: satisfied by `if fields is not None and f.name not in fields:`.
  The empty list is no longer conflated with `None`.

## F-002: Filter-before-read obligation is satisfied

- Classification: intent-derived side-effect/frame obligation, satisfied.
- Evidence: E-006, PO-FILTER-BEFORE-READ.
- Input: `model_to_dict(instance, fields=[])`.
- Expected behavior: no field values are read because no fields are requested.
- V1/V2 status: satisfied. The `fields is not None` membership check occurs
  before `f.value_from_object(instance)`, so every field continues before the
  value-read line when `fields=[]`.

## F-003: Adjacent truthiness checks are not part of this repair

- Classification: scope and compatibility finding, no source change justified.
- Evidence: E-001 through E-004, PO-CALLSITE-COMPATIBILITY.
- Observation: `repo/django/forms/models.py` contains other truthiness checks for
  variables named `fields`, including `_save_m2m()`.
- Expected action for this issue: audit and repair `model_to_dict()` according to
  its own docstring and the reported behavior.
- V1/V2 status: no additional production edit. The adjacent checks are in
  different behavioral surfaces, and this issue gives no public intent requiring
  their semantics to change. Changing them here would broaden the patch beyond
  the verified unit.

## F-004: Proof is constructed, not machine-checked

- Classification: proof capability / honesty gate.
- Evidence: PO-MACHINE-CHECK.
- Observation: this session is forbidden from running K tooling.
- Expected action: keep the proof labeled "constructed, not machine-checked" and
  do not remove tests based on it.
- V1/V2 status: satisfied. The run commands are recorded in the artifacts for a
  later environment.

## F-005: No unresolved code defect found in V1

- Classification: confirmation finding.
- Evidence: PO-EMPTY-FIELDS, PO-GENERAL-SELECTION, PO-EXCLUDE-PRECEDENCE,
  PO-FILTER-BEFORE-READ.
- Input class: all in-domain finite model field sequences with `fields` equal to
  `None`, `[]`, or a non-empty list of field names.
- Expected behavior: the returned dictionary is exactly the editable fields
  selected by `fields`, minus `exclude`.
- V1/V2 status: satisfied by the current source. V2 keeps V1 unchanged.

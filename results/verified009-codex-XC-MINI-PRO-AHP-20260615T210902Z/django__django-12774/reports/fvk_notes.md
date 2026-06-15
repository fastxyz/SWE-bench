FVK audit summary
=================

The FVK audit confirms the main V1 fix and makes one small V2 improvement.
Finding F1 and proof obligations PO1, PO2, and PO5 justify accepting a field
covered by an unconditional single-field `UniqueConstraint`; that is the
reported `slug` failure. Finding F2 and PO3 surfaced a completeness gap in V1:
Django metadata accepts both a relation field's `name` and `attname` as local
field identifiers, so the V2 source change compares constraint field
identifiers against both `field.name` and `field.attname`.

Changed source
==============

`repo/django/db/models/query.py`

The `in_bulk()` validation still accepts `pk` and `unique=True` fields exactly
as before, satisfying PO4. It now builds the set of one-field identifiers from
`opts.total_unique_constraints`, then accepts the requested field when that set
intersects `{field.name, field.attname}`. This addresses F1 and F2 without
altering query execution or dictionary construction, preserving the frame
condition in PO5.

Rejected alternatives
=====================

I did not accept composite `UniqueConstraint`s for a single `field_name`.
Finding F3 and PO6 reject that alternative because a composite constraint makes
the tuple unique, not each member field.

I did not accept conditional `UniqueConstraint`s. Finding F4 and PO6 reject
that alternative because `in_bulk()` needs a key that is unique across the
entire result set, and `Options.total_unique_constraints` intentionally excludes
conditional constraints.

I did not change batching, filtering, ordering reset, or the returned
dictionary. Those paths are outside the defect and are covered by the frame
condition in `fvk/SPEC.md`; no finding or proof obligation justified changing
them.

Execution constraints
=====================

Per F5 and PO7, I did not run tests, Python code, `kompile`, or `kprove`. The
FVK proof package records the commands and expected proof shape as constructed,
not machine-checked.

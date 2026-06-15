# Public Evidence Ledger

Status: constructed, not machine-checked.

This ledger mirrors the entries in `fvk/SPEC.md`.

E1: issue title, "Allow QuerySet.in_bulk() for fields with total
UniqueConstraints." Obligation: total single-field `UniqueConstraint`s qualify.

E2: issue reproduction, "If a field is unique by UniqueConstraint instead of
unique=True running in_bulk() on that field will fail." Obligation: the shown
`slug` case should not raise.

E3: `in_bulk()` docstring, "Return a dictionary mapping each of the given IDs
to the object with that ID." Obligation: the key must identify one object, so
composite uniqueness is insufficient for one field.

E4: existing error message. Obligation: preserve rejection of truly non-unique
fields.

E5: `Options.total_unique_constraints` docstring. Obligation: use this metadata
helper for total constraints.

E6: `Options.total_unique_constraints` implementation. Obligation: conditional
constraints are excluded.

E7: `Model._check_local_fields()` indexes both `field.name` and `field.attname`.
Obligation: compare qualifying constraint identifiers against both forms.

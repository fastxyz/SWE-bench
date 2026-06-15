# Formal Spec English

Status: constructed, not machine-checked.

CLAIM-ACCEPT-PK: validating `field_name="pk"` returns `allow`.

CLAIM-ACCEPT-UNIQUE: validating any non-primary-key field whose `unique` flag is
true returns `allow`.

CLAIM-ACCEPT-CONSTRAINT-NAME: validating a non-primary-key, non-unique field
returns `allow` when the constraints list contains a qualifying single total
constraint whose field identifier is the resolved field name.

CLAIM-ACCEPT-CONSTRAINT-ATTNAME: validating a non-primary-key, non-unique field
returns `allow` when the constraints list contains a qualifying single total
constraint whose field identifier is the resolved field attname.

CLAIM-REJECT-NON-UNIQUE: validating a non-primary-key, non-unique field returns
`reject` when no qualifying single total constraint matches either the field
name or attname.

Frame condition: when validation returns `allow`, the rest of `in_bulk()` uses
the existing filtering, batching, ordering reset, and dictionary construction.
